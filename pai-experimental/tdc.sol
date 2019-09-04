pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "./3rd/note.sol";
// import "../library/template.sol";
// import "./liquidator.sol";
// import "./price_oracle.sol";
// import "./pai_issuer.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/mathPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";

contract TDC is MathPI, DSNote, Template {
    //time deposit certificates
    event SetParam(uint paramType, uint param);
    //please check specific meaning of type in each method

    uint256 public TDCIndex = 0; /// how many CDPs have been created

    uint public baseInterestRate;

    //There are 5 kinds of cdps, one is current lending and the others are time lending. All time lending cdp will be liquidated when expire.
    enum TDCType {_30DAYS,_60DAYS,_90DAYS,_180DAYS,_360DAYS}
    mapping(uint8 => uint) public floatUp;
    mapping(uint8 => uint) public term;

    uint public totalPrincipal; /// total principal of all TDCs
    uint public totalInterest;/// total interest of all TDCs which can only be supplyed by PAIDAO.
                              /// It is not equal to the sum of all interest need to be payed of all TDCs,
                              /// it is only the number of fund prepared to pay for interest.


    PAIIssuer public issuer; /// contract to check the pai global assert ID.
    uint private ASSET_PAI;

    mapping (uint => TDCRecord) public TDCRecords; /// all TDC records

    struct TDCRecord {
        TDCType tdcType; ///see comments of enum TDCType
        address owner; /// owner of the TDC
        uint256 principal;
        uint256 interestRate;
        uint256 startTime;
    }

    constructor() public {
        baseInterestRate = RAY / 5; // Annual interest rate = 20 %
        floatUp[uint8(TDCType._30DAYS)] = RAY * 4 / 1000;
        floatUp[uint8(TDCType._60DAYS)] = RAY * 6 / 1000;
        floatUp[uint8(TDCType._90DAYS)] = RAY * 8 / 1000;
        floatUp[uint8(TDCType._180DAYS)] = RAY * 10 / 1000;
        floatUp[uint8(TDCType._360DAYS)] = RAY * 12 / 1000;
        term[uint8(TDCType._30DAYS)] = 30 days;
        term[uint8(TDCType._60DAYS)] = 60 days;
        term[uint8(TDCType._90DAYS)] = 90 days;
        term[uint8(TDCType._180DAYS)] = 180 days;
        term[uint8(TDCType._360DAYS)] = 360 days;
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.getAssetType();
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function updateBaseInterestRate(uint newRate) public note {
        require(newRate >= RAY);
        baseInterestRate = newRate;
        //emit SetParam(2,baseInterestRate);
    }

    function updateFloatUp(TDCType _type, uint _newFloatUp) public note {
        require(_type != TDCType.CURRENT);
        floatUp[uint8(_type)] = _newFloatUp;
        //emit SetCutDown(_type,_newCutDown);
    }

    /// @dev TDC base operations
    /// create a TDC
    function deposit(TDCType _type) public payable returns (uint record) {
        require(msg.assettype == ASSET_PAI);
        TDCIndex = add(TDCIndex, 1);
        record = TDCIndex;
        TDCRecords[record].owner = msg.sender;
        TDCRecords[record].tdcType = _type;
        TDCRecords[record].principal = msg.value;
        TDCRecords[record].interestRate = add(baseInterestRate,floatUp[uint8(_type)]);
        TDCRecords[record].startTime = era();
        totalPrincipal = add(totalPrincipal,msg.value);
        //emit CreateCDP(record,_type);
    }

    function addInterest() public payable {
        //Only PAIDAO can call
        require(msg.assettype == ASSET_PAI);
        totalInterest = add(totalInterest,msg.value);
        //emit CreateCDP(record,_type);
    }

    function withdraw(uint record, uint amount) public note {
        require(msg.sender == TDCRecords[record].owner);
        require(TDCRecords[record].principal >= amount);
        require(TDCRecords[record].owner != 0x0);
        totalPrincipal = sub(totalPrincipal,amount);
        TDCRecords[record].principal = sub(TDCRecords[record].principal,amount);
        msg.sender.transfer(amount,ASSET_PAI);
    }

    function checkMaturity(uint record) public view returns (bool) {
        if (0x0 == TDCRecords[record].owner) {
            return false;
        }
        return TDCRecords[record].startTime + term[uint8(TDCRecords[record].tdcType)] < era();
    }

    /// debt of CDP, include principal + interest
    function debtOfCDP(uint record) public returns (uint256,uint256) {
        CDPRecord storage data = CDPRecords[record];
        if (0x0 == data.owner)  {
            return (0,0);
        }
        uint debt;
        if(CDPType.CURRENT == data.cdpType) {
            debt = rmul(data.accumulatedDebt, updateAndFetchRates());
        } else {
            debt = data.accumulatedDebt;
        }
        uint interest = sub(debt,data.principal);
        return (data.principal,interest);
    }

    function totalCollateral() public view returns (uint256) {
        return flow.balance(this, ASSET_COLLATERAL);
    }

    function setPriceOracle(PriceOracle newPriceOracle) public {
        priceOracle = newPriceOracle;
    }

    function getCollateralPrice() public view returns (uint256 wad){
        return priceOracle.getPrice(ASSET_COLLATERAL);
    }

    function setLiquidator(Liquidator newLiquidator) public {
        liquidator = newLiquidator;
    }

    function setPAIIssuer(PAIIssuer newIssuer) public {
        issuer = newIssuer;
        ASSET_PAI = issuer.getAssetType();
    }

    function safe(uint record) public returns (bool) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        if(CDPType.CURRENT != data.cdpType && add(data.endTime,overdueBufferPeriod) < era()) {
            return false;
        }

        uint256 collateralValue = rmul(data.collateral, priceOracle.getPrice(ASSET_COLLATERAL));
        (uint principal,uint interest) = debtOfCDP(record);
        uint256 debtValue = rmul(add(principal,interest), liquidationRatio);
        return collateralValue >= debtValue;
    }

    function updateAndFetchRates() public returns (uint256) {
        updateRates();
        return accumulatedRates;
    }

    /// update `accumulatedRates1` and `accumulatedRates2` when borrow or repay happens
    function updateRates() public note {
        if(settlement) return;

        uint256 currentTimestamp = era();
        uint256 deltaSeconds = currentTimestamp - lastTimestamp;
        if (deltaSeconds == 0) return;

        lastTimestamp = currentTimestamp;
        if (baseInterestRate != RAY) {
            accumulatedRates = rmul(accumulatedRates, rpow(baseInterestRate, deltaSeconds));
        }
    }

    /// liquidate a CDP
    function liquidate(uint record) public note {
        require(!safe(record) || settlement);
        CDPRecord storage data = CDPRecords[record];
        (uint principal, uint interest) = debtOfCDP(record);
        liquidator.addDebt(principal);
        totalPrincipal = sub(totalPrincipal, principal);
        uint price = priceOracle.getPrice(ASSET_COLLATERAL);
        uint principalOfCollateral = rdiv(principal,price);
        uint interestOfCollateral = rdiv(interest,price);
        uint penaltyOfCollateral = rdiv(sub(rmul(principal, liquidationPenalty),principal),price);
        uint collateralToLiquidator;
        uint collateralLeft;
        if (data.collateral <= principalOfCollateral) {
            principalOfCollateral = data.collateral;
            collateralToLiquidator = data.collateral;
            interestOfCollateral = 0;
            penaltyOfCollateral = 0;
        } else if (data.collateral <= add(principalOfCollateral,interestOfCollateral)) {
            collateralToLiquidator = data.collateral;
            interestOfCollateral = sub(data.collateral, principalOfCollateral);
            penaltyOfCollateral = 0;
        } else if (data.collateral <= add(add(principalOfCollateral,interestOfCollateral),penaltyOfCollateral)) {
            collateralToLiquidator = data.collateral;
            penaltyOfCollateral = sub(sub(data.collateral, principalOfCollateral),interestOfCollateral);
        } else {
            collateralToLiquidator = add(add(principalOfCollateral,interestOfCollateral),penaltyOfCollateral);
            collateralLeft = sub(data.collateral, collateralToLiquidator);
            data.owner.transfer(collateralLeft, ASSET_COLLATERAL);
        }
        delete CDPRecords[record];
        emit CloseCDP(record);
        liquidator.transfer(collateralToLiquidator, ASSET_COLLATERAL);
        emit Liquidate(record, principalOfCollateral, interestOfCollateral, penaltyOfCollateral, collateralLeft);
    }

    function terminate() public note {
        require(!settlement);
        settlement = true;
        liquidationPenalty = RAY;
    }

    /// liquidate all CDPs after buffer period
    /// the settlement process turns to phase 2 after all CDPs are liquidated
    function quickLiquidate(uint _num) public note {
        require(settlement);
        require(liquidatedCDPIndex != CDPIndex);
        uint upperLimit = min(add(liquidatedCDPIndex, _num), CDPIndex);
        for(uint i = add(liquidatedCDPIndex,1); i <= upperLimit; i = add(i,1)) {
            if(CDPRecords[i].principal > 0)
                liquidate(i);
        }
        liquidatedCDPIndex = upperLimit;
    }

    /// working normal
    function inSettlement() public view returns (bool) {
        return settlement;
    }

    /// all debt cleared, ready for phase two
    function readyForPhaseTwo() public view returns (bool) {
        return totalPrincipal == 0 || liquidatedCDPIndex == CDPIndex;
    }
}