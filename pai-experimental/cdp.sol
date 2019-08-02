pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "./3rd/note.sol";
// import "../library/template.sol";
// import "./liquidator.sol";
// import "./price_oracle.sol";
// import "./pai_issuer.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/pai_issuer.sol";

contract CDP is DSMath, DSNote, Template {

    uint256 private CDPIndex = 0;

    /// 1000000000158153903837946257 => 0.5% ARP
    /// RAY + 0000000000158153903837946257*60*60*24*365 = 1004987541390500000..00
    uint private stabilityFee;
    uint private governanceFee;

    uint private lastTimestamp;
    uint private accumulatedRates1; /// accumulated rates of stability fees
    uint private accumulatedRates2; /// accumulated rates of stability fees + governance fees

    uint private totalNormalizedDebt; /// total debts of the CDP, calculated on accumulatedRates1
    uint private totalCollateralRecorded; /// TODO this should be replaced by flow.balanceOf()

    uint private liquidationRatio; /// liquidation ratio
    uint private liquidationPenalty; /// liquidation penalty

    uint private debtCeiling; /// debt ceiling

    bool private settlement; /// the business is in settlement stage
    uint private collateralSettlementPrice; /// collateral settlement price

    Liquidator private liquidator; /// address of the liquidator;
    PriceOracle private priceOracle; /// price oracle of BTC'/PAI and PIS/PAI
    PAIIssuer private issuer; /// contract to mint/burn PAI stable coin

    uint private BTC_ASSET_TYPE;
    uint private PAI_ASSET_TYPE;

    mapping (uint => CDPRecord) private CDPRecords; /// all CDP records

    address private hole = 0x660000000000000000000000000000000000000000;

    struct CDPRecord {
        address owner; /// owner of the CDP
        uint256 collateral; /// collateral in form of BTC'
        /// accumulated debts: principal + stability fees; 
        /// accumulatedDebt1 * accumulatedRates1 represents the debt with stability fees in real time
        uint256 accumulatedDebt1; 
        /// accumulated debts: principal + stability fees + governance fees; 
        /// accumulatedDebt2 * accumulatedRates2 represents the debt with stability fees and governance fees in real time
        uint256 accumulatedDebt2; 
    }

    constructor() public {
        stabilityFee = 1000100000000000000000000000;
        governanceFee = 1000000000000000000000000000;
        accumulatedRates1 = 1000000000000000000000000000;
        accumulatedRates2 = 1000000000000000000000000000;
        liquidationRatio = 1500000000000000000000000000;
        liquidationPenalty = 1130000000000000000000000000;

        lastTimestamp = block.timestamp;

        issuer = PAIIssuer(0x637be8293529b525c961c2dcf044db9540a526ae39);
        priceOracle = PriceOracle(0x6382529fd89effbd5db05404815bde497a4d604e08);
        liquidator = Liquidator(0x63fc8fbc0d5ffd30263722acbb27ed359e67d64c39);

        BTC_ASSET_TYPE = 0;
        PAI_ASSET_TYPE = issuer.getAssetType();
    }

    function readDebugParams() public view returns(uint, uint, uint, uint, uint, uint) {
        return (CDPIndex, lastTimestamp, accumulatedRates1, accumulatedRates2, totalNormalizedDebt, totalCollateralRecorded);
    }

    function readAssetTypes() public view returns(uint, uint) {
        return (BTC_ASSET_TYPE, PAI_ASSET_TYPE);
    }

    function createCDP() public note returns(uint record) {
        require(!settlement);
        CDPIndex = add(CDPIndex, 1);
        record = CDPIndex;
        CDPRecords[record].owner = msg.sender;
    }

    function transferCDPOwnership(uint record, address newOwner) public note {
        require(CDPRecords[record].owner == msg.sender);
        require(newOwner != msg.sender);
        require(newOwner != 0x0);
        CDPRecords[record].owner = newOwner;
    }

    function deposit(uint record) public payable note {
        require(!settlement);
        require(msg.assettype == BTC_ASSET_TYPE);
        require(CDPRecords[record].owner == msg.sender);

        uint rayAmount = satoshiToRay(msg.value);

        uint256 oldCollateral = CDPRecords[record].collateral;
        CDPRecords[record].collateral = add(oldCollateral, rayAmount);

        totalCollateralRecorded = add(totalCollateralRecorded, rayAmount);
        /// TODO only accept some amount range - DAI requires 0.005 ether at least
    }

    function withdraw(uint record, uint amount) public note {
        require(CDPRecords[record].owner == msg.sender);
        
        uint rayAmount = satoshiToRay(amount);

        uint256 oldCollateral = CDPRecords[record].collateral;
        CDPRecords[record].collateral = sub(oldCollateral, rayAmount);
        totalCollateralRecorded = sub(totalCollateralRecorded, rayAmount);

        require(safe(record));

        msg.sender.transfer(amount, BTC_ASSET_TYPE);
        /// TODO only accept some amount range - DAI requires 0.005 ether at least
    }

    function borrow(uint record, uint amount) public note {
        require(!settlement);
        require(CDPRecords[record].owner == msg.sender);

        /// new debt calculated on latest accumulatedRates1
        /// should be larger than the least allowed unit to calculate fees

        uint rayAmount = satoshiToRay(amount);

        uint newDebt1 = rdiv(rayAmount, updateAndFetchRates1());
        require(newDebt1 > 0);

        CDPRecords[record].accumulatedDebt1 = add(CDPRecords[record].accumulatedDebt1, newDebt1);
        totalNormalizedDebt = add(totalNormalizedDebt, newDebt1);

        uint newDebt2 = rdiv(rayAmount, updateAndFetchRates2());
        CDPRecords[record].accumulatedDebt2 = add(CDPRecords[record].accumulatedDebt2, newDebt2);

        require(safe(record));
        /// TODO check the total mint PAI has not exceed system limit - should be checked in issuer

        issuer.mint(amount, msg.sender);
    }

    function repay(uint record) public payable note {
        require(!settlement);
        require(msg.assettype == PAI_ASSET_TYPE);
       
        uint rayAmount = satoshiToRay(msg.value);
        uint change;

        uint newRepay1;

        uint newRepay2 = rdiv(rayAmount, updateAndFetchRates2());
        require(newRepay2 > 0);

        if(newRepay2 > CDPRecords[record].accumulatedDebt2) {
            /// note change is calculated in rates2
            change = rmul(sub(newRepay2, CDPRecords[record].accumulatedDebt2), updateAndFetchRates2());
            /// msg.sender.transfer(change / 10**19, PAI_ASSET_TYPE); /// TODO not secure!
            newRepay1 = CDPRecords[record].accumulatedDebt1;     
            newRepay2 = CDPRecords[record].accumulatedDebt2;       
        } else {
            uint debtRayAmount = rdiv(rmul(rayAmount, debtOfCDP(record)), debtOfCDPwithGovernanceFee(record));
            newRepay1 = rdiv(debtRayAmount, updateAndFetchRates1());
        }

        uint rayAmount1 = rdiv(rmul(sub(rayAmount, change), debtOfCDP(record)), debtOfCDPwithGovernanceFee(record));
        uint rayAmount2 = sub(sub(rayAmount, change), rayAmount1);
        
        CDPRecords[record].accumulatedDebt1 = sub(CDPRecords[record].accumulatedDebt1, newRepay1);
        totalNormalizedDebt = sub(totalNormalizedDebt, newRepay1);

        CDPRecords[record].accumulatedDebt2 = sub(CDPRecords[record].accumulatedDebt2, newRepay2);
        
        /// burn pai
        if(rayAmount1 > 0) {
            // hole.transfer(rayAmount1/10**19, PAI_ASSET_TYPE); /// TODO not secure!
            issuer.burn(rayToSatoshi(rayAmount1));
        }

        if(rayAmount2 > 0) {
            /// collect governance fee
            address(liquidator).transfer(rayToSatoshi(rayAmount2), PAI_ASSET_TYPE); /// TODO not secure!
        }

    }

    /// debt of CDP, include principal + stability fees
    /// sum of total debt in all CDP should equal to `totalNormalizedDebt`
    function debtOfCDP(uint record) public returns (uint256) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        return rmul(data.accumulatedDebt1, updateAndFetchRates1());
    }

    function debtOfCDPwithGovernanceFee(uint record) public returns (uint256) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        return rmul(data.accumulatedDebt2, updateAndFetchRates2());
    }


    function ownerOfCDP(uint record) public view returns (address) {
        return CDPRecords[record].owner;
    }

    function collateralOfCDP(uint record) public view returns (uint256) {
        return CDPRecords[record].collateral;
    }

    function totalDebt() public returns (uint256) {
        return rmul(totalNormalizedDebt, updateAndFetchRates1());
    }

    function totalCollateral() public view returns (uint256) {
        return totalCollateralRecorded;
    }

    function setPriceOracle(PriceOracle newPriceOracle) public {
        priceOracle = newPriceOracle;
    }

    function getCollateralPrice() public view returns (uint256 wad){
        return settlement ? collateralSettlementPrice : priceOracle.getPrice(BTC_ASSET_TYPE);
    }

    function setLiquidator(Liquidator newLiquidator) public {
        liquidator = newLiquidator;
    }

    function safe(uint record) public returns (bool) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);

        uint256 collateralValue = rmul(data.collateral, priceOracle.getPrice(BTC_ASSET_TYPE));
        uint256 debtValue = rmul(debtOfCDP(record), liquidationRatio);

        return collateralValue >= debtValue;
    }

    function satoshiToRay(uint amount) public pure returns (uint) {
        return mul(amount, 10**19);
    }

    function rayToSatoshi(uint rayAmount) public pure returns (uint) {
        return rayAmount / 10**19;
    }

    /// it is different in PAI to close a CDP compared with DAI
    /// we need to repay all debts before calling this function
    function closeCDPRecord(uint record) public note {
        require(!settlement);
        require(CDPRecords[record].owner == msg.sender);
        require(debtOfCDP(record) == 0 && debtOfCDPwithGovernanceFee(record) == 0);

        if(collateralOfCDP(record) > 0) {
            withdraw(record, rayToSatoshi(collateralOfCDP(record)));
        }
        delete CDPRecords[record];
    }

    function readDebugInfoOfCDP(uint record) public view returns (uint, uint, uint, uint, uint) {
        CDPRecord storage data = CDPRecords[record];
        return (data.collateral, data.accumulatedDebt1, rmul(data.accumulatedDebt1, accumulatedRates1), data.accumulatedDebt2, rmul(data.accumulatedDebt2, accumulatedRates2));
    }

    function updateAndFetchRates1() public returns (uint256) {
        updateRates();
        return accumulatedRates1;
    }

    function updateAndFetchRates2() public returns (uint256) {
        updateRates();
        return accumulatedRates2;
    }


    /// update `accumulatedRates1` and `accumulatedRates2` when borrow or repay happens
    function updateRates() public note {
        if(settlement) return;

        uint256 currentTimestamp = block.timestamp;
        uint256 deltaSeconds = currentTimestamp - lastTimestamp;
        if (deltaSeconds == 0) return; 
        lastTimestamp = currentTimestamp;

        uint256 temp = RAY;

        /// if stability fee is required
        if (stabilityFee != RAY) { 
            uint256 previousAccumulatedRates1 = accumulatedRates1;
            temp = rpow(stabilityFee, deltaSeconds);
            accumulatedRates1 = rmul(accumulatedRates1, temp);
            if(temp > 0 && totalNormalizedDebt > 0) {
                /// TODO not safe
                issuer.mint(rayToSatoshi(rmul(sub(accumulatedRates1,previousAccumulatedRates1), totalNormalizedDebt)), address(liquidator));
            }
        }

        // if governance fee is required
        if (governanceFee != RAY) {
            temp = rmul(temp, rpow(governanceFee, deltaSeconds));
        }
        if (temp != RAY) {
            accumulatedRates2 = rmul(accumulatedRates2, temp);
        }

    }

    function liquidate(uint record) public note {
        //require(!safe(record) || settlement);

        uint256 debt = debtOfCDP(record);
        liquidator.addDebt(rayToSatoshi(debt));
        totalNormalizedDebt = sub(totalNormalizedDebt, CDPRecords[record].accumulatedDebt1);
        CDPRecords[record].accumulatedDebt1 = 0;
        CDPRecords[record].accumulatedDebt2 = 0;

        uint256 collateralToLiquidator = rdiv(rmul(debt, liquidationPenalty), priceOracle.getPrice(BTC_ASSET_TYPE));
        if(collateralToLiquidator > CDPRecords[record].collateral) {
            collateralToLiquidator = CDPRecords[record].collateral;
        }
        
        CDPRecords[record].collateral = sub(CDPRecords[record].collateral, collateralToLiquidator);
        address(liquidator).transfer(rayToSatoshi(collateralToLiquidator), BTC_ASSET_TYPE);
    }

    function terminateBusiness(uint price) public note {
        require(!settlement && price != 0);
        settlement = true;
        liquidationPenalty = RAY;
        collateralSettlementPrice = price;
    }
    
}