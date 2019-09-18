pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_finance.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";

contract TDC is DSMath, DSNote, Template, ACLSlave {
    //time deposit certificates
    event SetParam(uint paramType, uint param);
    //please check specific meaning of type in each method
    event SetFloatUp(TDCType _type, uint _newFloatUp);
    event SetTerm(TDCType _type, uint _newTerm);
    event SetState(TDCType _type, bool newState);
    event SetContract(uint contractType, address contractAddress);
    //please check specific meaning of type in each method
    event FunctionSwitch(uint switchType, bool newState);
    //please check specific meaning of type in each method
    event CreateTDC(uint record, TDCType _type,address owner,uint principal, uint interestRate);
    event Withdraw(uint record, address owner, uint amount, uint8 withdrawType);
    //withdrawType == 0 represent withdraw happens when TDC isn't maturity
    //withdrawType == 1 represent withdraw happens when TDC is maturity
    event ReturnMoney(uint record,address owner,uint principal,uint interest);

    uint256 public TDCIndex = 0; /// how many TDCs have been created

    uint public baseInterestRate; ///annualized interest rate, in RAY

    //There are 10 kinds of TDCs.
    enum TDCType {_30DAYS,_60DAYS,_90DAYS,_180DAYS,_360DAYS,FLEXIABLE1,FLEXIABLE2,FLEXIABLE3,FLEXIABLE4,FLEXIABLE5}
    mapping(uint8 => uint) public floatUp;
    mapping(uint8 => uint) public term;
    mapping(uint8 => bool) public enable;

    PAIIssuer public issuer; /// contract to check the pai global assert ID.
    uint96 public ASSET_PAI;
    Finance public finance;
    Setting public setting;

    bool public disableDeposit;
    bool public disableGetInterest;

    mapping (uint => TDCRecord) public TDCRecords; /// all TDC records

    struct TDCRecord {
        TDCType tdcType; ///see comments of enum TDCType
        address owner; /// owner of the TDC
        uint256 principal;
        uint256 interestRate;
        uint256 startTime;
        uint256 principalPayed;
    }

    constructor(
        address paiMainContract,
        address _setting,
        address _issuer,
        address _finance
        ) public {
        master = ACLMaster(paiMainContract);
        setting = Setting(_setting);
        baseInterestRate = setting.depositInterestRate();
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.PAIGlobalId();
        finance = Finance(_finance);

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
        enable[uint8(TDCType._30DAYS)] = true;
        enable[uint8(TDCType._60DAYS)] = true;
        enable[uint8(TDCType._90DAYS)] = true;
        enable[uint8(TDCType._180DAYS)] = true;
        enable[uint8(TDCType._360DAYS)] = true;

    }

    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    function updateBaseInterestRate() public note {
        baseInterestRate = setting.depositInterestRate();
        emit SetParam(0,baseInterestRate);
    }

    function updateFloatUp(TDCType _type, uint _newFloatUp) public note auth("DIRECTORVOTE") {
        floatUp[uint8(_type)] = _newFloatUp;
        emit SetFloatUp(_type,_newFloatUp);
    }

    function updateTerm(TDCType _type, uint _newTerm) public note auth("DIRECTORVOTE") {
        require(_type > TDCType._360DAYS);
        term[uint8(_type)] = _newTerm;
        emit SetTerm(_type,_newTerm);
    }

    function changeState(TDCType _type, bool newState) public note auth("DIRECTORVOTE") {
        enable[uint8(_type)] = newState;
        emit SetState(_type,newState);
    }

    function switchDeposit(bool newState) public note auth("DIRECTORVOTE") {
        disableDeposit = newState;
        emit FunctionSwitch(0,newState);
    }

    function switchGetInterest(bool newState) public note auth("DIRECTORVOTE") {
        disableGetInterest = newState;
        emit FunctionSwitch(1,newState);
    }

    function setSetting(address _setting) public note auth("DIRECTORVOTE") {
        setting = Setting(_setting);
        emit SetContract(0,setting);
        baseInterestRate = setting.depositInterestRate();
        emit SetParam(0,baseInterestRate);
    }

    function setPAIIssuer(PAIIssuer newIssuer) public note auth("DIRECTORVOTE") {
        issuer = newIssuer;
        emit SetContract(1,issuer);
        ASSET_PAI = issuer.PAIGlobalId();
        emit SetParam(1,ASSET_PAI);
    }

    //function setFinance

    /// @dev TDC base operations
    /// create a TDC
    function deposit(TDCType _type) public payable returns (uint record) {
        require(setting.globalOpen());
        require(!disableDeposit);
        require(enable[uint8(_type)]);
        require(msg.assettype == ASSET_PAI);

        TDCIndex = add(TDCIndex, 1);
        record = TDCIndex;
        TDCRecords[record].tdcType = _type;
        TDCRecords[record].owner = msg.sender;
        TDCRecords[record].principal = msg.value;
        TDCRecords[record].interestRate = getInterestRate(_type);
        TDCRecords[record].startTime = timeNow();
        emit CreateTDC(record, _type, TDCRecords[record].owner, TDCRecords[record].principal, TDCRecords[record].interestRate);
    }

    function withdraw(uint record, uint amount) public note {
        require(setting.globalOpen());
        require(TDCRecords[record].owner != 0x0);
        require(msg.sender == TDCRecords[record].owner);
        require(sub(TDCRecords[record].principal, TDCRecords[record].principalPayed) >= amount);
        if (checkMaturity(record)) {
            TDCRecords[record].principalPayed = add(TDCRecords[record].principalPayed,amount);
            emit Withdraw(record,msg.sender,amount,1);
        } else {
            TDCRecords[record].principal = sub(TDCRecords[record].principal,amount);
            emit Withdraw(record,msg.sender,amount,0);
        }
        msg.sender.transfer(amount,ASSET_PAI);
    }

    function checkMaturity(uint record) public view returns (bool) {
        if (0x0 == TDCRecords[record].owner) {
            return false;
        }
        return timeNow() >= TDCRecords[record].startTime + term[uint8(TDCRecords[record].tdcType)] ;
    }

    function getInterestRate(TDCType _type) public view returns (uint) {
        return add(baseInterestRate,floatUp[uint8(_type)]);
    }

    function passedTime(uint record) public view returns (uint) {
        if (0x0 == TDCRecords[record].owner) {
            return 0;
        }
        return sub(timeNow(),TDCRecords[record].startTime);
    }

    function returnMoney(uint record) public note {
        require(setting.globalOpen());
        require(!disableGetInterest);
        require(TDCRecords[record].owner != 0x0);
        require(TDCRecords[record].principal != 0);
        require(checkMaturity(record));
        uint interest = mul(TDCRecords[record].principal,rmul(TDCRecords[record].interestRate, term[uint8(TDCRecords[record].tdcType)])) / 1 years;
        uint principal = sub(TDCRecords[record].principal,TDCRecords[record].principalPayed);
        if (principal > 0) {
            TDCRecords[record].owner.transfer(principal,ASSET_PAI);
        }
        TDCRecords[record].principal = 0;
        //finance.payForInterest(167,TDCRecords[record].owner);
        emit ReturnMoney(record,TDCRecords[record].owner,principal,interest);
    }
}