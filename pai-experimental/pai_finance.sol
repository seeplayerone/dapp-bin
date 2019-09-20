pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";

contract Finance is Template,ACLSlave,DSMath {
    PAIIssuer public issuer;
    Setting public setting;
    PriceOracle public priceOracle;
    address public tdc;
    bool private initTdc;
    uint96 public ASSET_PAI;
    uint96 public ASSET_PIS;
    uint public operationCashLimit;
    uint public safePad;
    uint public PISmintValue;  // in PAI
    uint public lastAirDropCashOut;
    uint public applyAmount;
    uint public applyNonce;
    uint public applyTime;
    address public applyAddr;
    address public PISseller;


    constructor(address paiMainContract, address _issuer, address _setting, address _oracle) public {
        master = ACLMaster(paiMainContract);
        issuer = PAIIssuer(_issuer);
        setting = Setting(_setting);
        ASSET_PAI = issuer.PAIGlobalId();
        priceOracle = PriceOracle(_oracle);
        ASSET_PIS = priceOracle.ASSET_COLLATERAL();
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

    function mintPIS() public {
        require(0x0 != PISseller);
        require(flow.balance(PISseller,ASSET_PIS) == 0);
        require(flow.balance(this,ASSET_PAI) < safePad);
        require(0 != PISmintValue);
        uint amount = rdiv(PISmintValue,priceOracle.getPrice());
        PAIDAO(master).autoMint(amount,PISseller);
    }

    function setAssetPIS(address newPriceOracle) public auth("PISVOTE") {
        priceOracle = PriceOracle(newPriceOracle);
        ASSET_PIS = priceOracle.ASSET_COLLATERAL();
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

    function setPISseller(address newSeller) public auth("PISVOTE") {
        PISseller = newSeller;
    }

    function payForInterest(uint amount, address receiver) public auth("TDCContract") {
        require(amount > 0);
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

    function payForDividends(uint amount, address receiver) public auth("DividendsContract") {
        require(amount > 0);
        receiver.transfer(amount,ASSET_PAI);
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
        uint CashOutLimit = rmul(sub(sub(totalSupply,depositNumber),flow.balance(this,ASSET_PAI)),mul(delta,setting.depositInterestRate())) / 1 years;
        if (CashOutLimit > amount) {
            applyAmount = amount;
        } else {
            applyAmount = CashOutLimit;
        }
        applyNonce = add(applyNonce,1);
        applyAddr = msg.sender;
        applyTime = timeNow();
    }

    function approvalAirDropCashOut(uint nonce, bool result) public auth("CFO") {
        require(nonce == applyNonce);
        require(applyAmount > 0);
        if(result) {
            lastAirDropCashOut = applyTime;
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

    function setSafePad(uint amount) public auth("PISVOTE") {
        safePad = amount;
    }

    function setPISmintValue(uint amount) public auth("PISVOTE") {
        PISmintValue = amount;
    }

    function cashOut(uint amount, address dest) public auth("PISVOTE") {
        require(amount > 0);
        dest.transfer(amount,ASSET_PAI);
    }
}