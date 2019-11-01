pragma solidity 0.4.25;

import "../library/utils/math_lg.sol";
import "../library/utils/ds_note.sol";
import "../library/template.sol";
import "./pi_liquidator.sol";
import "./pi_price_oracle.sol";
import "./pi_issuer.sol";
import "./pi_setting.sol";
import "../library/acl_slave.sol";

contract CDP is MathPI, DSNote, Template, ACLSlave {

    event SetParam(uint paramType, uint param);
    //please check specific meaning of type in each method
    event SetContract(uint contractType, address contractAddress);
    //please check specific meaning of type in each method
    event SetRateAdj(CDPType _type, int _newRateAdj);
    event UpdateBaseInterestRateAdjustment(int baseInterestRateAdjustment);
    event SetTerm(CDPType _type, uint _newTerm);
    event SetState(CDPType _type, bool newState);
    event FunctionSwitch(uint switchType, bool newState);
    //please check specific meaning of type in each method
    event PostCDP(uint CDPid, address newOwner, uint price);
    event BuyCDP(uint CDPid, address newOwner, uint price);
    event CreateCDP(uint _index, CDPType _type);
    event DepositCollateral(uint collateral, uint principal, uint debt, uint _index, uint depositAmount);
    event BorrowPAI(uint collateral, uint principal, uint debt, uint _index, uint borrowAmount, uint endTime);
    event RepayPAI(uint collateral, uint principal, uint debt, uint _index, uint repayAmount, uint repayAmount1, uint repayAmount2);
    event CloseCDP(uint _index);
    event Liquidate(uint _index, uint principalOfCollateral, uint interestOfCollateral, uint penaltyOfCollateral, uint collateralLeft, uint price);
    event LiquidateType(uint8 typeEnum); //typeEnum == 0, global liquidate;typeEnum == 1, insolvency liquidate;typeEnum == 2, overdue liquidate;

    uint256 public CDPIndex = 0; /// how many CDPs have been created
    uint256 private liquidatedCDPIndex = 0; /// how many CDPs have been liquidated, only happens when the business is in settlement process

    //uint public baseInterestRate;
    int public baseInterestRateAdjustment;
    uint public annualizedInterestRate;
    uint public secondInterestRate; //  actually, it represents 1 + secondInterestRate

    //There are 11 kinds of cdps, one is current lending and the others are time lending. All time lending cdp will be liquidated when expire.
    enum CDPType {CURRENT,_30DAYS,_60DAYS,_90DAYS,_180DAYS,_360DAYS,FLEXIABLE1,FLEXIABLE2,FLEXIABLE3,FLEXIABLE4,FLEXIABLE5}
    mapping(uint8 => int) public rateAdj;
    mapping(uint8 => uint) public term;
    mapping(uint8 => bool) public enable;
    uint public overdueBufferPeriod = 3 days;

    //the default collateral ration when creating cdp is 200%, however there are 5% tolerance ratio to deal with fluctuation
    uint public createCollateralRatio = 2 * RAY;
    uint public createToleranceRatio = RAY / 20;  //5%

    //data for CDP exchange
    struct approval{
        address buyer;
        uint price;
    }
    mapping(uint => approval) approvals;

    //memory data for liquidate
    struct LiquidateData {
        uint principalOfCollateral;
        uint interestOfCollateral;
        uint penaltyOfCollateral;
    }

    //If the difference between the money paid and the debt is less than one hour's interest,
    //The close request is still accepted
    uint private closeCDPToleranceTime = 1 hours;

    uint private lastTimestamp;
    uint public accumulatedRates = RAY; /// accumulated rates of current lending fees

    uint public totalPrincipal; /// total principal of all CDPs

    uint public liquidationRatio = RAY * 3 / 2; /// liquidation ratio
    uint public liquidationPenalty1 = RAY * 113 / 100; /// liquidation penalty when insolvency
    uint public liquidationPenalty2 = RAY * 105 / 100; /// liquidation penalty when overdue
    uint private lowerBorrowingLimit = 500000000; /// user should borrow at lest 5PAI once.
                                    //1000000000

    uint public debtCeiling; /// debt ceiling, in collatral

    bool public settlement; /// the business is in settlement stage
    bool public disableCDPTransfer;

    Liquidator public liquidator; /// address of the liquidator
    PriceOracle public priceOracle; /// price oracle of collateral
    PAIIssuer public issuer; /// contract to mint/burn PAI stable coin
    Setting public setting;  /// contract to storage global parameters
    address public finance;  /// contract to be send profits

    uint96 public ASSET_COLLATERAL;
    uint96 public ASSET_PAI;

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
        /// accumulatedDebt represents the debt composed by principal + interests, and need no more transformation
        uint256 accumulatedDebt;
        /// endTime only works when cdp is time lending.
        uint256 endTime;
    }

    constructor(
        address pisContract,
        address _issuer,
        address _oracle,
        address _liquidator,
        address _setting,
        address _finance,
        uint _debtCeiling
        ) public {
        master = ACLMaster(pisContract);
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.PAIGlobalId();
        priceOracle = PriceOracle(_oracle);
        liquidator = Liquidator(_liquidator);
        setting = Setting(_setting);
        finance = _finance;
        ASSET_COLLATERAL = priceOracle.assetId();
        debtCeiling = _debtCeiling;

        baseInterestRateAdjustment = 0;
        rateAdj[uint8(CDPType.CURRENT)] = -int(RAY * 2 / 1000);
        annualizedInterestRate = getInterestRate(CDPType.CURRENT);
        secondInterestRate = optimalExp(generalLog(add(RAY, annualizedInterestRate)) / 1 years);
        rateAdj[uint8(CDPType._30DAYS)] = -int(RAY * 4 / 1000);
        rateAdj[uint8(CDPType._60DAYS)] = -int(RAY * 6 / 1000);
        rateAdj[uint8(CDPType._90DAYS)] = -int(RAY * 8 / 1000);
        rateAdj[uint8(CDPType._180DAYS)] = -int(RAY * 10 / 1000);
        rateAdj[uint8(CDPType._360DAYS)] = -int(RAY * 12 / 1000);
        term[uint8(CDPType._30DAYS)] = 30 days;
        term[uint8(CDPType._60DAYS)] = 60 days;
        term[uint8(CDPType._90DAYS)] = 90 days;
        term[uint8(CDPType._180DAYS)] = 180 days;
        term[uint8(CDPType._360DAYS)] = 360 days;
        enable[uint8(CDPType.CURRENT)] = true;
        enable[uint8(CDPType._30DAYS)] = true;
        enable[uint8(CDPType._60DAYS)] = true;
        enable[uint8(CDPType._90DAYS)] = true;
        enable[uint8(CDPType._180DAYS)] = true;
        enable[uint8(CDPType._360DAYS)] = true;

        lastTimestamp = block.timestamp;
    }

    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    function updateBaseInterestRate() public note {
        updateRates();
        emit SetParam(10, setting.lendingInterestRate());
        annualizedInterestRate = getInterestRate(CDPType.CURRENT);
        secondInterestRate = optimalExp(generalLog(add(RAY, annualizedInterestRate)) / 1 years);
        emit SetParam(2, annualizedInterestRate);
        emit SetParam(8, secondInterestRate);
    }

    /// @notice cutdown adjustment of CDPType.CUREENT will affect existing cdps, the design should be verified
    function updateRateAdj(CDPType _type, int _newRateAdj) public note auth("50%Demonstration@STCoin") {
        rateAdj[uint8(_type)] = _newRateAdj;
        emit SetRateAdj(_type,_newRateAdj);
        if(CDPType.CURRENT == _type) {
            updateRates();
            annualizedInterestRate = getInterestRate(CDPType.CURRENT);
            secondInterestRate = optimalExp(generalLog(add(RAY, annualizedInterestRate)) / 1 years);
            emit SetParam(2, annualizedInterestRate);
            emit SetParam(8, secondInterestRate);
        }
    }

    function updateBaseInterestRateAdjustment(int _newRateAdj) public note auth("50%Demonstration@STCoin") {
        updateRates();
        baseInterestRateAdjustment = _newRateAdj;
        annualizedInterestRate = getInterestRate(CDPType.CURRENT);
        secondInterestRate = optimalExp(generalLog(add(RAY, annualizedInterestRate)) / 1 years);
        emit UpdateBaseInterestRateAdjustment(baseInterestRateAdjustment);
    }

    function updateTerm(CDPType _type, uint _newTerm) public note auth("100%Demonstration@STCoin") {
        require(_type > CDPType._360DAYS);
        term[uint8(_type)] = _newTerm;
        emit SetTerm(_type,_newTerm);
    }

    function changeState(CDPType _type, bool newState) public note auth("50%DemPreVote@STCoin") {
        enable[uint8(_type)] = newState;
        emit SetState(_type,newState);
    }

    function updateCDPTransferState(bool newState) public note auth("50%DemPreVote@STCoin") {
        disableCDPTransfer = newState;
        emit FunctionSwitch(0,newState);
    }

    function updateCreateCollateralRatio(uint newRatio, uint newTolerance) public note auth("50%DemPreVote@STCoin") {
        require(newRatio - newTolerance >= liquidationRatio);
        require(newTolerance <= RAY / 10);
        createCollateralRatio = newRatio;
        createToleranceRatio = newTolerance;
        emit SetParam(3,newRatio);
        emit SetParam(4,newTolerance);
    }

    function updateLiquidationRatio(uint newRatio) public note auth("50%DemPreVote@STCoin") {
        require(newRatio <= createCollateralRatio - createToleranceRatio);
        require(newRatio >= RAY);
        liquidationRatio = newRatio;
        emit SetParam(5,liquidationRatio);
    }

    function updateLiquidationPenalty1(uint newPenalty) public note auth("50%DemPreVote@STCoin") {
        require(newPenalty >= RAY);
        liquidationPenalty1 = newPenalty;
        emit SetParam(6,liquidationPenalty1);
    }

    function updateLiquidationPenalty2(uint newPenalty) public note auth("50%DemPreVote@STCoin") {
        require(newPenalty >= RAY);
        liquidationPenalty2 = newPenalty;
        emit SetParam(9,liquidationPenalty2);
    }

    function updateDebtCeiling(uint newCeiling) public note auth("50%DemPreVote@STCoin") {
        debtCeiling = newCeiling;
        emit SetParam(7,debtCeiling);
    }

    /// transfer ownership of a CDP
    function transferCDPOwnership(uint record, address newOwner, uint price) public note {
        require(setting.globalOpen());
        require(!disableCDPTransfer);
        require(CDPRecords[record].owner == msg.sender);
        require(newOwner != msg.sender);
        require(newOwner != 0x0);
        if(0 == price) {
            CDPRecords[record].owner = newOwner;
        } else {
            approvals[record].buyer = newOwner;
            approvals[record].price = price;
        }
        emit PostCDP(record, newOwner, price);
    }

    function buyCDP(uint record) public payable note {
        require(setting.globalOpen());
        require(!disableCDPTransfer);
        require(msg.assettype == ASSET_PAI);
        require(msg.sender == approvals[record].buyer);
        require(msg.value >= approvals[record].price);
        CDPRecords[record].owner.transfer(msg.value, ASSET_PAI);
        CDPRecords[record].owner = msg.sender;
        if(msg.value > approvals[record].price) {
            uint repay = msg.value - approvals[record].price;
            msg.sender.transfer(repay,ASSET_PAI);
        }
        delete approvals[record];
        emit BuyCDP(record, msg.sender, msg.value);
    }

    /// @dev CDP base operations
    /// create a CDP
    function createCDPInternal(CDPType _type) internal returns (uint record) {
        require(!settlement);
        require(enable[uint8(_type)]);
        CDPIndex = add(CDPIndex, 1);
        record = CDPIndex;
        CDPRecords[record].owner = msg.sender;
        CDPRecords[record].cdpType = _type;
        emit CreateCDP(record,_type);
    }

    /// deposit BTC
    function deposit(uint record) public payable note {
        require(setting.globalOpen());
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
            emit BorrowPAI(data.collateral, data.principal,rmul(data.accumulatedDebt, accumulatedRates), record, amount,0);
        } else {
            newDebt = add(amount,rmul(amount, mul(getInterestRate(data.cdpType), term[uint8(data.cdpType)])) / 1 years);
            data.accumulatedDebt = add(data.accumulatedDebt, newDebt);
            data.endTime = add(timeNow(), term[uint8(data.cdpType)]);
            emit BorrowPAI(data.collateral, data.principal, data.accumulatedDebt, record, amount,data.endTime);
        }
        require(safe(record));

        issuer.mint(amount, msg.sender);
    }

    /// create CDP + deposit BTC + borrow PAI
    function createDepositBorrow(uint amount, CDPType _type) public payable note returns(uint) {
        require(setting.globalOpen());
        require(mul(msg.value, priceOracle.getPrice()) / amount >= sub(createCollateralRatio,createToleranceRatio));
        require(amount >= lowerBorrowingLimit);
        require(add(msg.value,totalCollateral()) <= debtCeiling);
        uint totalPaiSupply = issuer.totalSupply();
        require(add(totalPrincipal,amount) <= rmul(add(totalPaiSupply,amount), setting.mintPaiRatioLimit(ASSET_COLLATERAL)) || 0 == totalPaiSupply);
        uint id = createCDPInternal(_type);
        depositInternal(id);
        borrowInternal(id, amount);
        return id;
    }

    function repay(uint record) public payable note {
        require(setting.globalOpen());
        repayInternal(record);
    }

    /// repay PAI
    function repayInternal(uint record) internal {
        require(!settlement);
        require(msg.assettype == ASSET_PAI);
        require(msg.value > 0);
        require(msg.sender == CDPRecords[record].owner);
        CDPRecord storage data = CDPRecords[record];
        //uint change;
        (uint principal,uint interest) = debtOfCDP(record);
        uint payForPrincipal;
        uint payForInterest;
        if (
                (
                    msg.value >= add(principal,interest)
                )
                ||
                (
                    CDPType.CURRENT == data.cdpType
                    && msg.value >= principal
                    && rmul(msg.value,rpow(secondInterestRate,closeCDPToleranceTime)) >= add(principal,interest)
                )
           )
        {
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
            finance.transfer(payForInterest, ASSET_PAI);
        }
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
        if (debt < data.principal) {
            return (data.principal,0);
        }
        return (data.principal,sub(debt,data.principal));
    }

    function totalCollateral() public view returns (uint256) {
        return flow.balance(this, ASSET_COLLATERAL);
    }

    function getCollateralPrice() public view returns (uint256) {
        return priceOracle.getPrice();
    }

    function setLiquidator(address newLiquidator) public note auth("100%Demonstration@STCoin") {
        liquidator = Liquidator(newLiquidator);
        emit SetContract(1,liquidator);
    }

    function setOracle(address newPriceOracle) public note auth("100%Demonstration@STCoin") {
        priceOracle = PriceOracle(newPriceOracle);
        require(ASSET_COLLATERAL == priceOracle.assetId());
        emit SetContract(2,priceOracle);
    }

    function setSetting(address _setting) public note auth("100%Demonstration@STCoin") {
        setting = Setting(_setting);
        emit SetContract(3,setting);
        updateBaseInterestRate();
    }

    function setFinance(address _finance) public note auth("100%Demonstration@STCoin") {
        finance = _finance;
        emit SetContract(4,finance);
    }

    function safe(uint record) public returns (bool) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);

        uint256 collateralValue = rmul(data.collateral, priceOracle.getPrice());
        (uint principal,uint interest) = debtOfCDP(record);
        uint256 debtValue = rmul(add(principal,interest), liquidationRatio);
        return collateralValue >= debtValue;
    }

    function overdue(uint record) public view returns (bool) {
        CDPRecord storage data = CDPRecords[record];
        require(data.owner != 0x0);
        if(CDPType.CURRENT != data.cdpType && add(data.endTime,overdueBufferPeriod) < timeNow()) {
            return true;
        }
        return false;
    }

    function updateAndFetchRates() public returns (uint256) {
        updateRates();
        return accumulatedRates;
    }

    function updateRates() public note {
        if(settlement) return;

        uint256 currentTimestamp = timeNow();
        uint256 deltaSeconds = currentTimestamp - lastTimestamp;
        if (deltaSeconds == 0) return;

        lastTimestamp = currentTimestamp;
        if (secondInterestRate != RAY) {
            accumulatedRates = rmul(accumulatedRates, rpow(secondInterestRate, deltaSeconds));
        }
    }

    /// liquidate a CDP
    function liquidate(uint record) public note {
        require(setting.globalOpen());
        uint liquidationPenalty;
        if(settlement) {
            liquidationPenalty = RAY;
            emit LiquidateType(0);
        } else if (!safe(record)) {
            liquidationPenalty = liquidationPenalty1;
            emit LiquidateType(1);
        } else if (overdue(record)) {
            liquidationPenalty = liquidationPenalty2;
            emit LiquidateType(2);
        } else {
            return;
        }
        CDPRecord storage data = CDPRecords[record];
        if (0x0 == data.owner ) {
            return;
        }
        (uint principal, uint interest) = debtOfCDP(record);
        liquidator.addDebt(principal);
        totalPrincipal = sub(totalPrincipal, principal);
        LiquidateData memory ld;
        uint price = priceOracle.getPrice();
        ld.principalOfCollateral = rdiv(principal,price);
        ld.interestOfCollateral = rdiv(interest,price);
        ld.penaltyOfCollateral = rdiv(sub(rmul(principal, liquidationPenalty),principal),price);
        uint collateralToLiquidator;
        uint collateralLeft;
        if (data.collateral <= ld.principalOfCollateral) {
            ld.principalOfCollateral = data.collateral;
            collateralToLiquidator = data.collateral;
            ld.interestOfCollateral = 0;
            ld.penaltyOfCollateral = 0;
        } else if (data.collateral <= add(ld.principalOfCollateral,ld.interestOfCollateral)) {
            collateralToLiquidator = data.collateral;
            ld.interestOfCollateral = sub(data.collateral, ld.principalOfCollateral);
            ld.penaltyOfCollateral = 0;
        } else if (data.collateral <= add(add(ld.principalOfCollateral,ld.interestOfCollateral),ld.penaltyOfCollateral)) {
            collateralToLiquidator = data.collateral;
            ld.penaltyOfCollateral = sub(sub(data.collateral, ld.principalOfCollateral),ld.interestOfCollateral);
        } else {
            collateralToLiquidator = add(add(ld.principalOfCollateral,ld.interestOfCollateral),ld.penaltyOfCollateral);
            collateralLeft = sub(data.collateral, collateralToLiquidator);
            data.owner.transfer(collateralLeft, ASSET_COLLATERAL);
        }
        delete CDPRecords[record];
        emit CloseCDP(record);
        address(liquidator).transfer(collateralToLiquidator, ASSET_COLLATERAL);
        emit Liquidate(record, ld.principalOfCollateral, ld.interestOfCollateral, ld.penaltyOfCollateral, collateralLeft, price);
    }

    function getInterestRate(CDPType _type) public view returns(uint rate) {
        rate = setting.lendingInterestRate();
        if(baseInterestRateAdjustment > 0 ){
            rate = add(rate,uint(baseInterestRateAdjustment));
        } else {
            rate = sub(rate,uint(-baseInterestRateAdjustment));
        }
        if(rateAdj[uint8(_type)] > 0) {
            rate = add(rate,uint(rateAdj[uint8(_type)]));
        } else {
            rate = sub(rate,uint(-rateAdj[uint8(_type)]));
        }
    }

    function terminate() public note auth("Settlement@STCoin") {
        require(!settlement);
        settlement = true;
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

    /// all debt cleared, ready for phase two
    function readyForPhaseTwo() public view returns (bool) {
        return totalPrincipal == 0 || liquidatedCDPIndex == CDPIndex;
    }
}