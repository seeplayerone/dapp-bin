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
import "github.com/evilcc2018/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";

contract CDP is MathPI, DSNote, Template {

    event SetParam(uint paramType, uint param);
    //please check specific meaning of type in each method
    event SetCutDown(CDPType _type, uint _newCutDown);
    event PostCDP(uint CDPid, address newOwner, uint price);
    event BuyCDP(uint CDPid, address newOwner, uint price);
    event CreateCDP(uint _index, CDPType _type);
    event DepositCollateral(uint collateral, uint principal, uint debt, uint _index, uint depositAmount);
    event BorrowPAI(uint collateral, uint principal, uint debt, uint _index, uint borrowAmount);
    event RepayPAI(uint collateral, uint principal, uint debt, uint _index, uint repayAmount, uint repayAmount1, uint repayAmount2);
    event CloseCDP(uint _index);
    event Liquidate(uint _index, uint principalOfCollateral, uint interestOfCollateral, uint penaltyOfCollateral, uint collateralLeft);

    uint256 public CDPIndex = 0; /// how many CDPs have been created
    uint256 private liquidatedCDPIndex = 0; /// how many CDPs have been liquidated, only happens when the business is in settlement process

    uint public baseInterestRate;///actually, the value is (1 + base interest rate)

    //There are 7 kinds of cdps, one is current lending and the others are time lending. All time lending cdp will be liquidated when expire.
    enum CDPType {CURRENT,_30DAYS,_60DAYS,_90DAYS,_180DAYS,_360DAYS}
    mapping(uint8 => uint) public cutDown;
    mapping(uint8 => uint) public adjustedInterestRate;
    mapping(uint8 => uint) public term;
    uint public overdueBufferPeriod = 3 days;

    //The CollateralRatio limit when cdp is created;
    uint public createCollateralRatio = 2 * RAY;
    uint public createRatioTolerance = RAY / 20;  //5%

    //data for CDP exchange
    struct approval{
        address canBuyAddr;
        uint price;
    }
    mapping(uint => approval) approvals;

    //If the difference between the money paid and the debt is less than one hour's interest,
    //The close request is still accepted
    uint public closeCDPToleranceTime = 1 hours;

    uint private lastTimestamp;
    uint private accumulatedRates; /// accumulated rates of current lending fees

    uint public totalPrincipal; /// total principal of all CDPs

    uint public liquidationRatio; /// liquidation ratio
    uint public liquidationPenalty; /// liquidation penalty
    uint private lowerBorrowingLimit = 10000000 /// user should borrow at lest 0.1PAI once.

    uint public debtCeiling; /// debt ceiling

    bool private settlement; /// the business is in settlement stage

    Liquidator public liquidator; /// address of the liquidator;
    PriceOracle public priceOracle; /// price oracle of BTC'/PAI and PIS/PAI
    PAIIssuer public issuer; /// contract to mint/burn PAI stable coin

    uint private ASSET_COLLATERAL;
    uint private ASSET_PAI;

    mapping (uint => CDPRecord) public CDPRecords; /// all CDP records

    struct CDPRecord {
        CDPType cdpType; ///see comments of enum CDPType
        address owner; /// owner of the CDP
        uint256 collateral; /// collateral amount
        uint256 principal;
        /// accumulatedDebt represents two meanings:
        /// 1. CDP is current lending:
        /// accumulatedDebt * accumulatedRates represents the debt composed by principal + interests
        /// 2. CDP is time lending:
        /// accumulatedDebt represents represents the debt composed by principal + interests, and need no more transformation
        uint256 accumulatedDebt;
        /// endTime only works when cdp is time lending.
        uint256 endTime;
    }

    constructor(address _issuer, address _oracle, address _liquidator) public {
        baseInterestRate = 1000000005781380000000000000; // Annual interest rate = 20 %
        accumulatedRates = RAY;
        liquidationRatio = 1500000000000000000000000000;
        liquidationPenalty = 1130000000000000000000000000;
        cutDown[uint8(CDPType._30DAYS)] = RAY * 4 / 1000;
        cutDown[uint8(CDPType._60DAYS)] = RAY * 6 / 1000;
        cutDown[uint8(CDPType._90DAYS)] = RAY * 8 / 1000;
        cutDown[uint8(CDPType._180DAYS)] = RAY * 10 / 1000;
        cutDown[uint8(CDPType._360DAYS)] = RAY * 12 / 1000;
        updateInterestRate(CDPType._30DAYS);
        updateInterestRate(CDPType._60DAYS);
        updateInterestRate(CDPType._90DAYS);
        updateInterestRate(CDPType._180DAYS);
        updateInterestRate(CDPType._360DAYS);
        term[uint8(CDPType._30DAYS)] = 30 days;
        term[uint8(CDPType._60DAYS)] = 60 days;
        term[uint8(CDPType._90DAYS)] = 90 days;
        term[uint8(CDPType._180DAYS)] = 180 days;
        term[uint8(CDPType._360DAYS)] = 360 days;

        debtCeiling = 0;

        lastTimestamp = era();

        issuer = PAIIssuer(_issuer);
        priceOracle = PriceOracle(_oracle);
        liquidator = Liquidator(_liquidator);

        ASSET_COLLATERAL = 0;
        ASSET_PAI = issuer.getAssetType();
    }

    function setAssetPAI(uint assetType) public note {
        ASSET_PAI = assetType;
        emit SetParam(0,ASSET_PAI);
    }

    function setAssetCollateral(uint assetType) public note {
        ASSET_COLLATERAL = assetType;
        emit SetParam(1,ASSET_COLLATERAL);
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function updateBaseInterestRate(uint newRate) public note {
        require(newRate >= RAY);
        updateRates();
        baseInterestRate = optimalExp(generalLog(newRate) / 1 years);
        updateInterestRate(CDPType._30DAYS);
        updateInterestRate(CDPType._60DAYS);
        updateInterestRate(CDPType._90DAYS);
        updateInterestRate(CDPType._180DAYS);
        updateInterestRate(CDPType._360DAYS);
        emit SetParam(2,baseInterestRate);
    }

    function updateInterestRate(CDPType _type) internal {
        require(_type != CDPType.CURRENT);
        adjustedInterestRate[uint8(_type)] = optimalExp(generalLog(sub(rpow(baseInterestRate, 1 years), cutDown[uint8(_type)])) / 1 years);
        require(adjustedInterestRate[uint8(_type)] >= RAY);
    }

    function updateCutDown(CDPType _type, uint _newCutDown) public note {
        require(_type != CDPType.CURRENT);
        cutDown[uint8(_type)] = _newCutDown;
        updateInterestRate(_type);
        emit SetCutDown(_type,_newCutDown);
    }

    function updateCreateCollateralRatio(uint _newRatio, uint _newTolerance) public note {
        require(_newRatio - _newTolerance >= liquidationRatio);
        require(_newTolerance <= RAY / 10);
        createCollateralRatio = _newRatio;
        createRatioTolerance = _newTolerance;
        emit SetParam(3,_newRatio);
        emit SetParam(4,_newTolerance);
    }

    function updateLiquidationRatio(uint newRatio) public note {
        require(newRatio >= RAY);
        liquidationRatio = newRatio;
        emit SetParam(5,liquidationRatio);
    }

    function updateLiquidationPenalty(uint newPenalty) public note {
        require(newPenalty >= RAY);
        liquidationPenalty = newPenalty;
        emit SetParam(6,liquidationPenalty);
    }

    function updateDebtCeiling(uint newCeiling) public note {
        debtCeiling = newCeiling;
        emit SetParam(7,debtCeiling);
    }

    /// transfer ownership of a CDP
    function transferCDPOwnership(uint record, address newOwner, uint _price) public note {
        require(CDPRecords[record].owner == msg.sender);
        require(newOwner != msg.sender);
        require(newOwner != 0x0);
        if(0 == _price) {
            CDPRecords[record].owner = newOwner;
        } else {
            approvals[record].canBuyAddr = newOwner;
            approvals[record].price = _price;
        }
        emit PostCDP(record, newOwner, _price);
    }

    function buyCDP(uint record) public payable note {
        require(msg.assettype == ASSET_PAI);
        require(msg.sender == approvals[record].canBuyAddr);
        require(msg.value == approvals[record].price);
        CDPRecords[record].owner = msg.sender;
        delete approvals[record];
        emit BuyCDP(record, msg.sender, msg.value);
    }

    /// @dev CDP base operations
    /// create a CDP
    function createCDPInternal(CDPType _type) internal returns (uint record) {
        require(!settlement);
        CDPIndex = add(CDPIndex, 1);
        record = CDPIndex;
        CDPRecords[record].owner = msg.sender;
        CDPRecords[record].cdpType = _type;
        emit CreateCDP(record,_type);
    }

    /// deposit BTC
    function deposit(uint record) public payable note {
        depositInternal(record);
    }

    function depositInternal(uint record) internal {
        require(!settlement);
        require(msg.assettype == ASSET_COLLATERAL);
        require(CDPRecords[record].owner == msg.sender);

        CDPRecords[record].collateral = add(CDPRecords[record].collateral, msg.value);

        CDPRecord storage data = CDPRecords[record];
        if (CDPType.CURRENT == data.cdpType) {
            emit DepositCollateral(data.collateral, data.principal, rmul(data.accumulatedDebt, accumulatedRates), record, msg.value);
        } else {
            emit DepositCollateral(data.collateral, data.principal, data.accumulatedDebt, record, msg.value);
        }
    }

    /// borrow PAI
    function borrowInternal(uint record, uint amount) internal {
        require(!settlement);
        require(CDPRecords[record].owner == msg.sender);
        require(amount > 0);

        CDPRecord storage data = CDPRecords[record];
        data.principal = add(data.principal, amount);
        totalPrincipal = add(totalPrincipal, amount);
        uint newDebt;
        if (CDPType.CURRENT == data.cdpType) {
            newDebt = rdiv(amount, updateAndFetchRates());
            data.accumulatedDebt = add(data.accumulatedDebt, newDebt);
            emit BorrowPAI(data.collateral, data.principal,rmul(data.accumulatedDebt, accumulatedRates), record, amount);
        } else {
            newDebt = rmul(amount, rpow(adjustedInterestRate[uint8(data.cdpType)], term[uint8(data.cdpType)]));
            data.accumulatedDebt = add(data.accumulatedDebt, newDebt);
            CDPRecords[record].endTime = add(era(), term[uint8(data.cdpType)]);
            emit BorrowPAI(data.collateral, data.principal, data.accumulatedDebt, record, amount);
        }
        require(safe(record));
        /// TODO debt ceiling check

        issuer.mint(amount, msg.sender);
    }

    /// create CDP + deposit BTC + borrow PAI
    function createDepositBorrow(uint amount, CDPType _type) public payable note returns(uint) {
        require(mul(msg.value, priceOracle.getPrice(ASSET_COLLATERAL)) / amount >= sub(createCollateralRatio,createRatioTolerance));
        require(amount >= lowerBorrowingLimit);
        uint id = createCDPInternal(_type);
        depositInternal(id);
        borrowInternal(id, amount);
        return id;
    }

    function repay(uint record) public payable note {
        repayInternal(record);
    }

    /// repay PAI
    function repayInternal(uint record) internal {
        require(!settlement);
        require(msg.assettype == ASSET_PAI);
        require(msg.value > 0);
        CDPRecord storage data = CDPRecords[record];
        //uint change;
        (uint principal,uint interest) = debtOfCDP(record);
        uint payForPrincipal;
        uint payForInterest;
        if(msg.value >= principal && rmul(msg.value,rpow(baseInterestRate,closeCDPToleranceTime)) >= add(principal,interest)) {
            //Actually there are little difference between Current and Time lending, but considering the
            //huge improvement in logic predication, the difference is ignored.
            //This will cause a little loss in interest income of Time lending.
            uint change = 0;
            if(msg.value > add(principal,interest)) {
                change = sub(msg.value,add(principal,interest));
                msg.sender.transfer(change, ASSET_PAI);
                payForPrincipal = principal;
                payForInterest = sub(msg.value,add(change,principal));
            } else  {
                payForPrincipal = principal;
                payForInterest = sub(msg.value,principal);
            }
            if(data.collateral > 0) {
                msg.sender.transfer(data.collateral, ASSET_COLLATERAL);
            }
            totalPrincipal = sub(totalPrincipal,principal);
            emit RepayPAI(data.collateral, 0, 0, record, msg.value, payForPrincipal, payForInterest);
            delete CDPRecords[record];
            emit CloseCDP(record);
        } else {
            if (msg.value >= interest) {
                payForInterest = interest;
                payForPrincipal = sub(msg.value, payForInterest);
            } else {
                payForInterest = msg.value;
                payForPrincipal = 0;
            }
            data.principal = sub(data.principal,payForPrincipal);
            totalPrincipal = sub(totalPrincipal,payForPrincipal);
            if(CDPType.CURRENT == data.cdpType) {
                data.accumulatedDebt = sub(data.accumulatedDebt, rdiv(msg.value,updateAndFetchRates()));
                emit RepayPAI(data.collateral, data.principal, rmul(data.accumulatedDebt, accumulatedRates), record, msg.value, payForPrincipal, payForInterest);
            } else {
                data.accumulatedDebt = sub(data.accumulatedDebt, msg.value);
                emit RepayPAI(data.collateral, data.principal, data.accumulatedDebt, record, msg.value, payForPrincipal, payForInterest);
            }
        }
        if (payForPrincipal > 0) {
            issuer.burn.value(payForPrincipal, ASSET_PAI)();
        }
        if(payForInterest > 0) {
            liquidator.transfer(payForInterest, ASSET_PAI);
        }
        // TODO transfer to Financial Contracts directly
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