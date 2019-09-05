pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/mathPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_financial.sol";

contract TDC is MathPI, DSNote, Template {
    //time deposit certificates
    event SetParam(uint paramType, uint param);
    //please check specific meaning of type in each method

    uint256 public TDCIndex = 0; /// how many CDPs have been created

    uint public baseInterestRate;

    //There are 5 kinds of TDCs.
    enum TDCType {_30DAYS,_60DAYS,_90DAYS,_180DAYS,_360DAYS}
    mapping(uint8 => uint) public floatUp;
    mapping(uint8 => uint) public term;

    PAIIssuer public issuer; /// contract to check the pai global assert ID.
    uint private ASSET_PAI;
    Financial public financial;

    mapping (uint => TDCRecord) public TDCRecords; /// all TDC records

    struct TDCRecord {
        TDCType tdcType; ///see comments of enum TDCType
        address owner; /// owner of the TDC
        uint256 principal;
        uint256 interestRate;
        uint256 startTime;
    }

    constructor(address _issuer, address _financial) public {
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
        financial = Financial(_financial);
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function updateBaseInterestRate(uint newRate) public note {
        baseInterestRate = newRate;
        //emit SetParam(2,baseInterestRate);
    }

    function updateFloatUp(TDCType _type, uint _newFloatUp) public note {
        floatUp[uint8(_type)] = _newFloatUp;
        //emit SetCutDown(_type,_newCutDown);
    }

    /// @dev TDC base operations
    /// create a TDC
    function deposit(TDCType _type) public payable returns (uint record) {
        require(msg.assettype == ASSET_PAI);
        TDCIndex = add(TDCIndex, 1);
        record = TDCIndex;
        TDCRecords[record].tdcType = _type;
        TDCRecords[record].owner = msg.sender;
        TDCRecords[record].principal = msg.value;
        TDCRecords[record].interestRate = getInterestRate(_type);
        TDCRecords[record].startTime = era();
        //emit CreateCDP(record,_type);
    }

    function withdraw(uint record, uint amount) public note {
        require(TDCRecords[record].owner != 0x0);
        require(msg.sender == TDCRecords[record].owner);
        require(TDCRecords[record].principal >= amount);
        TDCRecords[record].principal = sub(TDCRecords[record].principal,amount);
        msg.sender.transfer(amount,ASSET_PAI);
    }

    function checkMaturity(uint record) public view returns (bool) {
        if (0x0 == TDCRecords[record].owner) {
            return false;
        }
        return era() >= TDCRecords[record].startTime + term[uint8(TDCRecords[record].tdcType)] ;
    }

    function getInterestRate(TDCType _type) public view returns (uint) {
        return add(baseInterestRate,floatUp[uint8(_type)]);
    }

    function passedTime(uint record) public view returns (uint) {
        if (0x0 == TDCRecords[record].owner) {
            return 0;
        }
        return sub(era(),TDCRecords[record].startTime);
    }

    function returnMoney(uint record) public note {
        require(TDCRecords[record].owner != 0x0);
        require(TDCRecords[record].principal != 0);
        require(checkMaturity(record));
        uint interest = mul(TDCRecords[record].principal,rmul(TDCRecords[record].interestRate, term[uint8(TDCRecords[record].tdcType)])) / 1 years;
        TDCRecords[record].principal = 0;
        TDCRecords[record].owner.transfer(TDCRecords[record].principal,ASSET_PAI);
        financial.payForInterest(interest,TDCRecords[record].owner);
    }

    function setPAIIssuer(PAIIssuer newIssuer) public {
        issuer = newIssuer;
        ASSET_PAI = issuer.getAssetType();
    }
}