pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";

contract Finance is Template,ACLSlave,DSMath {
    PAIIssuer public issuer;
    Setting public setting;
    address public tdc;
    bool private initTdc;
    uint96 public ASSET_PAI;
    uint public operationCashLimit;
    uint private lastAirDropCashOut;
    uint private applyAmount;
    uint applyNonce;
    address applyAddr;


    constructor(address paiMainContract, address _issuer, address _setting) public {
        master = ACLMaster(paiMainContract);
        issuer = PAIIssuer(_issuer);
        setting = Setting(_setting);
        ASSET_PAI = issuer.PAIGlobalId();
    }

    function init(address _tdc) public {
        require(!initTdc);
        initTdc = true;
        tdc = _tdc;
    }

    function() public payable {
        require(msg.assettype == ASSET_PAI);
    }

    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    function setPAIIssuer(address newIssuer) public auth("DIRECTORVOTE") {
        require(flow.balance(this,ASSET_PAI) == 0);
        issuer = PAIIssuer(newIssuer);
        ASSET_PAI = issuer.PAIGlobalId();
    }

    function setSetting(address _setting) public auth("DIRECTORVOTE") {
        setting = Setting(_setting);
    }

    function setTDC(address _tdc) public auth("DIRECTORVOTE") {
        tdc = _tdc;
    }

    function payForInterest(uint amount, address receiver) public auth("TDCContract") {
        receiver.transfer(amount,ASSET_PAI);
    }

    function payForDebt(uint amount) public auth("LiqudatorContract") {
        if (0 == amount)
            return;
        if (flow.balance(this,ASSET_PAI) > amount) {
            msg.sender.transfer(amount,ASSET_PAI);
        } else {
            msg.sender.transfer(flow.balance(this,ASSET_PAI),ASSET_PAI);
        }
    }

    function payForDividends(uint amount) public auth("DividendsContract") {
        require(amount > 0);
        msg.sender.transfer(amount,ASSET_PAI);
    }

    function applyForAirDropCashOut(uint amount) public auth("AirDropAddr") {
        require(amount > 0);
        (,,,,,uint totalSupply) = issuer.getAssetInfo(0);
        uint depositNumber = flow.balance(tdc,ASSET_PAI);
        uint delta;
        if (0 == lastAirDropCashOut) {
            delta = 1 days;
        } else {
            delta = sub(timeNow(),lastAirDropCashOut);
        }
        uint CashOutLimit = rmul(sub(totalSupply,depositNumber),mul(delta,setting.depositInterestRate())) / 1 years;
        if (CashOutLimit > amount) {
            applyAmount = amount;
        } else {
            applyAmount = CashOutLimit;
        }
        applyNonce = add(applyNonce,1);
        applyAddr = msg.sender;
    }

    function approvalAirDropCashOut(uint nonce, bool result) public auth("CFO") {
        require(nonce == applyNonce);
        require(applyAmount > 0);
        if(result) {
            lastAirDropCashOut = timeNow();
            applyAddr.transfer(applyAmount,ASSET_PAI);
            applyAmount = 0;
            return;
        }
        applyAmount = 0;
    }

    function operationCashOut(uint amount, address dest) public auth("CFO") {
        require(amount > 0);
        require(operationCashLimit >= amount);
        operationCashLimit = sub(operationCashLimit,amount);
        dest.transfer(amount,ASSET_PAI);
    }

    function increaseOperationCashLimit(uint amount) public auth("PISVOTE") {
        operationCashLimit = add(operationCashLimit,amount);
    }

    function cashOut(uint amount, address dest) public auth("PISVOTE") {
        require(amount > 0);
        dest.transfer(amount,ASSET_PAI);
    }
}