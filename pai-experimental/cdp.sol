pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "./3rd/note.sol";
// import "../library/template.sol";
// import "./liquidator.sol";
// import "./price_oracle.sol";
// import "./pai_issuer.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";

contract CDP is DSMath, DSNote, Template {

    event CreateCDP(uint _index);
    event DepositBTC(uint collateral, uint debt1, uint debt2, uint _index, uint depositAmount);
    event WithdrawBTC(uint collateral, uint debt1, uint debt2, uint _index, uint withdrawAmount);
    event BorrowPAI(uint collateral, uint debt1, uint debt2, uint _index, uint borrowAmount);
    event RepayPAI(uint collateral, uint debt1, uint debt2, uint _index, uint repayAmount, uint repayAmount1, uint repayAmount2);
    event CloseCDP(uint _index);
    event DebtOfCDP(uint _debt);
    event DebtOfCDPWithGovernanceFee(uint _debt);
    event TotalDebt(uint _debt);
    event Safe(bool _safe);
    event Liquidate(uint collateral, uint debt1, uint debt2, uint _index, uint debtToLiquidator, uint collateralToLiquidator);

    uint256 private CDPIndex = 0;
    uint256 private liquidatedCDP = 0;

    /// usually we only set one of them
    uint private stabilityFee; /// stability fee is calculated for liquidation, the fee is pre issued and sent to liquidator whenever rates change
    uint private governanceFee; /// governance fee is not calculated for liquidation, the fee is deducted whenever users repay the borrows

    uint private lastTimestamp;
    uint private accumulatedRates1; /// accumulated rates of stability fees
    uint private accumulatedRates2; /// accumulated rates of stability fees + governance fees

    uint private totalNormalizedDebt; /// total debts of the CDP, calculated on accumulatedRates1

    uint private liquidationRatio; /// liquidation ratio
    uint private liquidationPenalty; /// liquidation penalty

    uint private debtCeiling; /// debt ceiling

    bool private settlement; /// the business is in settlement stage

    Liquidator private liquidator; /// address of the liquidator;
    PriceOracle private priceOracle; /// price oracle of BTC'/PAI and PIS/PAI
    PAIIssuer private issuer; /// contract to mint/burn PAI stable coin

    uint private ASSET_BTC;
    uint private ASSET_PAI;

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

    constructor(address _issuer, address _oracle, address _liquidator) public {
        stabilityFee = 1000000000000000000000000000;
        governanceFee = 1000000000000000000000000000;
        accumulatedRates1 = 1000000000000000000000000000;
        accumulatedRates2 = 1000000000000000000000000000;
        liquidationRatio = 1500000000000000000000000000;
        liquidationPenalty = 1130000000000000000000000000;

        lastTimestamp = block.timestamp;

        issuer = PAIIssuer(_issuer);
        priceOracle = PriceOracle(_oracle);
        liquidator = Liquidator(_liquidator);

        ASSET_BTC = 0;
        ASSET_PAI = issuer.getAssetType();
    }

    function updateStabilityFee(uint newFee) public {
        require(newFee >= RAY);
        updateRates();
        stabilityFee = newFee;
    }

    function updateGovernanceFee(uint newFee) public {
        require(newFee >= RAY);
        updateRates();
        governanceFee = newFee;
    }

    function updateLiquidationRatio(uint newRatio) public {
        require(newRatio >= RAY);
        liquidationRatio = newRatio;
    }

    function updateLiquidationPenalty(uint newPenalty) public {
        require(newPenalty >= RAY);
        liquidationPenalty = newPenalty;
    }

    /// @dev CDP base operations
    /// create a CDP
    function createCDP() public note returns(uint record) {
        return createCDPInternal();
    }

    function createCDPInternal() internal returns (uint record) {
        require(!settlement);
        CDPIndex = add(CDPIndex, 1);
        record = CDPIndex;
        CDPRecords[record].owner = msg.sender;
        emit CreateCDP(record);
    }

    /// transfer ownership of a CDP
    function transferCDPOwnership(uint record, address newOwner) public note {
        require(CDPRecords[record].owner == msg.sender);
        require(newOwner != msg.sender);
        require(newOwner != 0x0);
        CDPRecords[record].owner = newOwner;
    }

    /// deposit BTC
    function deposit(uint record) public payable note {
        depositInternal(record);
    }

    function depositInternal(uint record) internal {
        require(!settlement);
        require(msg.assettype == ASSET_BTC);
        require(CDPRecords[record].owner == msg.sender);

        CDPRecords[record].collateral = add(CDPRecords[record].collateral, msg.value);

        CDPRecord storage data = CDPRecords[record];
        emit DepositBTC(data.collateral, rmul(data.accumulatedDebt1, accumulatedRates1), rmul(data.accumulatedDebt2, accumulatedRates2), record, msg.value);        
    }

    /// withdraw BTC
    function withdraw(uint record, uint amount) public note {
        require(CDPRecords[record].owner == msg.sender);
        
        CDPRecords[record].collateral = sub(CDPRecords[record].collateral, amount);

        require(safe(record));
        msg.sender.transfer(amount, ASSET_BTC);

        CDPRecord storage data = CDPRecords[record];
        emit WithdrawBTC(data.collateral, rmul(data.accumulatedDebt1, accumulatedRates1), rmul(data.accumulatedDebt2, accumulatedRates2), record, amount);
    }

    /// borrow PAI
    function borrow(uint record, uint amount) public note {
        borrowInternal(record, amount);
    }

    function borrowInternal(uint record, uint amount) internal {
        require(!settlement);
        require(CDPRecords[record].owner == msg.sender);

        uint newDebt1 = rdiv(amount, updateAndFetchRates1());
        require(newDebt1 > 0);

        CDPRecords[record].accumulatedDebt1 = add(CDPRecords[record].accumulatedDebt1, newDebt1);
        totalNormalizedDebt = add(totalNormalizedDebt, newDebt1);

        uint newDebt2 = rdiv(amount, updateAndFetchRates2());
        CDPRecords[record].accumulatedDebt2 = add(CDPRecords[record].accumulatedDebt2, newDebt2);

        require(safe(record));
        /// TODO check the total mint PAI has not exceed system limit - should be checked in issuer

        issuer.mint(amount, msg.sender);

        CDPRecord storage data = CDPRecords[record];
        emit BorrowPAI(data.collateral, rmul(data.accumulatedDebt1, accumulatedRates1), rmul(data.accumulatedDebt2, accumulatedRates2), record, amount);
    }

    /// create CDP + deposit BTC + borrow PAI
    function createDepositBorrow(uint amount) public payable note {
        uint id = createCDPInternal();
        depositInternal(id);
        borrowInternal(id, amount);
    }

    /// repay PAI
    function repay(uint record) public payable note {
        require(!settlement);
        require(msg.assettype == ASSET_PAI);
       
        uint change;
        uint newRepay1;
        uint newRepay2 = rdiv(msg.value, updateAndFetchRates2());
        require(newRepay2 > 0);

        uint repay1Ratio = rdiv(debtOfCDP(record), debtOfCDPwithGovernanceFee(record));
        /// there could be precision loss
        if(repay1Ratio > RAY) {
            repay1Ratio = RAY; 
        }

        if(newRepay2 > CDPRecords[record].accumulatedDebt2) {
            /// note change is calculated in rates2
            change = rmul(sub(newRepay2, CDPRecords[record].accumulatedDebt2), updateAndFetchRates2());
            msg.sender.transfer(change, ASSET_PAI);
            newRepay1 = CDPRecords[record].accumulatedDebt1;     
            newRepay2 = CDPRecords[record].accumulatedDebt2;       
        } else {
            //uint debtAmount = rmul(msg.value, repay1Ratio);
            newRepay1 = rdiv(rmul(msg.value, repay1Ratio), updateAndFetchRates1());
        }

        uint amount1 = rmul(sub(msg.value, change), repay1Ratio);
        uint amount2 = sub(sub(msg.value, change), amount1);
        
        CDPRecords[record].accumulatedDebt1 = sub(CDPRecords[record].accumulatedDebt1, newRepay1);
        totalNormalizedDebt = sub(totalNormalizedDebt, newRepay1);

        CDPRecords[record].accumulatedDebt2 = sub(CDPRecords[record].accumulatedDebt2, newRepay2);
        
        /// burn pai
        if(amount1 > 0) {
            hole.transfer(amount1, ASSET_PAI);
            issuer.burn(amount1);
        }

        /// governance fee to liquidator
        if(amount2 > 0) {
            address(liquidator).transfer(amount2, ASSET_PAI);
        }

        CDPRecord storage data = CDPRecords[record];
        emit RepayPAI(data.collateral, rmul(data.accumulatedDebt1, accumulatedRates1), rmul(data.accumulatedDebt2, accumulatedRates2), record, msg.value, amount1, amount2);

    }

    /// close CDP
    function closeCDPRecord(uint record) public note {
        require(!settlement);
        require(CDPRecords[record].owner == msg.sender);
        require(debtOfCDP(record) == 0 && debtOfCDPwithGovernanceFee(record) == 0);

        if(collateralOfCDP(record) > 0) {
            withdraw(record, collateralOfCDP(record));
        }
        delete CDPRecords[record];

        emit CloseCDP(record);
    }

    /// debt of CDP, include principal + stability fees
    function debtOfCDP(uint record) public returns (uint256) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        uint debt = rmul(data.accumulatedDebt1, updateAndFetchRates1());
        emit DebtOfCDP(debt);
        return debt;
    }

    /// debt of CDP, include principal + stability fees + governance fees
    function debtOfCDPwithGovernanceFee(uint record) public returns (uint256) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        uint debt = rmul(data.accumulatedDebt2, updateAndFetchRates2());
        emit DebtOfCDPWithGovernanceFee(debt);
        return debt;
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
        return flow.balance(this, ASSET_BTC);
    }

    function setPriceOracle(PriceOracle newPriceOracle) public {
        priceOracle = newPriceOracle;
    }

    function getCollateralPrice() public view returns (uint256 wad){
        return priceOracle.getPrice(ASSET_BTC);
    }

    function setLiquidator(Liquidator newLiquidator) public {
        liquidator = newLiquidator;
    }

    function setPAIIssuer(PAIIssuer newIssuer) public {
        issuer = newIssuer;
    }

    function safe(uint record) public returns (bool) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);

        uint256 collateralValue = rmul(data.collateral, priceOracle.getPrice(ASSET_BTC));
        uint256 debtValue = rmul(debtOfCDP(record), liquidationRatio);

        emit Safe(collateralValue >= debtValue);
        return collateralValue >= debtValue;
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
                issuer.mint(rmul(sub(accumulatedRates1,previousAccumulatedRates1), totalNormalizedDebt), address(liquidator));
                liquidator.cancelDebt();
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

    /// liquidate a CDP
    function liquidate(uint record) public note {
        require(!safe(record)||settlement);

        uint256 debt = debtOfCDP(record);
        liquidator.addDebt(debt);
        totalNormalizedDebt = sub(totalNormalizedDebt, CDPRecords[record].accumulatedDebt1);
        CDPRecords[record].accumulatedDebt1 = 0;
        CDPRecords[record].accumulatedDebt2 = 0;

        uint256 collateralToLiquidator = rdiv(rmul(debt, liquidationPenalty), priceOracle.getPrice(ASSET_BTC));
        if(collateralToLiquidator > CDPRecords[record].collateral) {
            collateralToLiquidator = CDPRecords[record].collateral;
        }
        
        CDPRecords[record].collateral = sub(CDPRecords[record].collateral, collateralToLiquidator);
        address(liquidator).transfer(collateralToLiquidator, ASSET_BTC);

        CDPRecord storage data = CDPRecords[record];
        emit Liquidate(data.collateral, rmul(data.accumulatedDebt1, accumulatedRates1), rmul(data.accumulatedDebt2, accumulatedRates2), record, debt, collateralToLiquidator);
    }

    function terminateBusiness() public note {
        require(!settlement && price != 0);
        updateRates();
        settlement = true;
        liquidationPenalty = RAY;
        priceOracle.terminate();
        liquidator.settlePhaseOne();
    }

    function quickLiquidate(uint _num) public note {
        require(settlement);
        require(liquidatedCDP != CDPIndex);
        uint upperLimit = min(add(liquidatedCDP, _num), CDPIndex);
        for(uint i = add(liquidatedCDP,1); i <= upperLimit; i = add(i,1)) {
            if(CDPRecords[i].accumulatedDebt1 > 0)
                liquidate(i);
        }
        liquidatedCDP = upperLimit;
        if(liquidatedCDP == CDPIndex)
            liquidator.settlePhaseTwo();
    }

    /// @dev debug functions

    function debug() public view returns(uint, uint, uint, uint, uint, uint) {
        return (CDPIndex, lastTimestamp, accumulatedRates1, accumulatedRates2, totalNormalizedDebt, flow.balance(this, ASSET_BTC));
    }

    function debugCDP(uint record) public view returns (uint, uint, uint, uint, uint) {
        CDPRecord storage data = CDPRecords[record];
        return (data.collateral, data.accumulatedDebt1, rmul(data.accumulatedDebt1, accumulatedRates1), data.accumulatedDebt2, rmul(data.accumulatedDebt2, accumulatedRates2));
    }

    function readCDP(uint record) public view returns(address, uint, uint, uint){
        return (CDPRecords[record].owner,CDPRecords[record].collateral,CDPRecords[record].accumulatedDebt1,CDPRecords[record].accumulatedDebt2);
    }

    function checkSafe(uint record) public view returns (bool) {
        return safe(record);
    }

    function reOpen() public {
        settlement = false;
        liquidationPenalty = 1130000000000000000000000000;
        liquidatedCDP = 0;
        liquidator.reOpen();
        priceOracle.reOpen();
    }

    function liquidateProgress() public view returns (uint, uint) {
        return (liquidatedCDP, CDPIndex);
    }
}