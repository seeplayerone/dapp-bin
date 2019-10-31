pragma solidity 0.4.25;

import "../library/template.sol";
import "./pi_issuer.sol";
import "../library/acl_slave.sol";
import "./pi_setting.sol";
import "./pis_main.sol";
import "./pi_price_oracle.sol";

contract Finance is Template,ACLSlave,DSMath {
    PAIIssuer public issuer;
    Setting public setting;
    PriceOracle public priceOracle;
    address public tdc;
    uint96 public ASSET_PAI;
    uint96 public ASSET_PIS;
    uint public operationCashLimit;
    uint public safePad;
    uint public PISmintRate;  // in PAI,in RAY
    uint public lastAirDropCashOut;
    uint public applyAmount;
    uint public applyNonce;
    uint public applyTime;
    address public applyAddr;
    address public PISseller;


    constructor(address paiMainContract, address _issuer, address _setting, address _oracle) public {
        master = ACLMaster(paiMainContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
        issuer = PAIIssuer(_issuer);
        setting = Setting(_setting);
        ASSET_PAI = issuer.PAIGlobalId();
        priceOracle = PriceOracle(_oracle);
        require(ASSET_PIS == priceOracle.assetId());
    }

    function() public payable {
        require(msg.assettype == ASSET_PAI);
    }

    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    /// @notice 为什么是任意人都能调用啊？
    function mintPIS() public {
        require(0x0 != PISseller);
        require(flow.balance(PISseller,ASSET_PIS) == 0);
        require(flow.balance(this,ASSET_PAI) < safePad);
        require(0 != PISmintRate);
        uint amount = rmul(safePad,PISmintRate);
        amount = rdiv(amount,priceOracle.getPrice());
        PAIDAO(master).autoMint(amount,PISseller);
    }

    function setOracle(address newPriceOracle) public auth("PISVOTE") {
        priceOracle = PriceOracle(newPriceOracle);
        require(ASSET_PIS == priceOracle.assetId());
    }

    function setSetting(address _setting) public auth("100%Demonstration@STCoin") {
        setting = Setting(_setting);
    }

    function setTDC(address _tdc) public auth("100%Demonstration@STCoin") {
        tdc = _tdc;
    }

    function setPISseller(address newSeller) public auth("DirPisVote") {
        PISseller = newSeller;
    }

    function payForInterest(uint amount, address receiver) public auth("TDC@STCoin") {
        require(amount > 0);
        receiver.transfer(amount,ASSET_PAI);
    }

    function payForDebt(uint amount) public auth("Liqudator@STCoin") {
        if (0 == amount)
            return;
        if (flow.balance(this,ASSET_PAI) > amount) {
            msg.sender.transfer(amount,ASSET_PAI);
        } else {
            msg.sender.transfer(flow.balance(this,ASSET_PAI),ASSET_PAI);
        }
    }

    function payForDividends(uint amount, address receiver) public auth("Dividends@STCoin") {
        require(amount > 0);
        receiver.transfer(amount,ASSET_PAI);
    }

    function applyForAirDropCashOut(uint amount) public auth("AirDrop@STCoin") {
        require(amount > 0);
        uint totalSupply = issuer.totalSupply();
        uint depositNumber = flow.balance(tdc,ASSET_PAI);
        uint delta;
        if (0 == lastAirDropCashOut) {
            delta = 1 days;
        } else {
            delta = sub(timeNow(),lastAirDropCashOut);
        }
        uint CashOutLimit = mul(delta,setting.currentDepositRate());
        CashOutLimit =rmul(sub(sub(totalSupply,depositNumber),flow.balance(this,ASSET_PAI)),CashOutLimit) / 1 years;
        if (CashOutLimit > amount) {
            applyAmount = amount;
        } else {
            applyAmount = CashOutLimit;
        }
        applyNonce = add(applyNonce,1);
        applyAddr = msg.sender;
        applyTime = timeNow();
    }

    function approvalAirDropCashOut(uint nonce, bool result) public auth("CFO@STCoin") {
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

    function operationCashOut(uint amount, address dest) public auth("CFO@STCoin") {
        require(amount > 0);
        require(operationCashLimit >= amount);
        operationCashLimit = sub(operationCashLimit,amount);
        dest.transfer(amount,ASSET_PAI);
    }

    function increaseOperationCashLimit(uint amount) public auth("DirPisVote@STCoin") {
        operationCashLimit = add(operationCashLimit,amount);
    }

    function setSafePad(uint amount) public auth("50%DemPreVote@STCoin") {
        safePad = amount;
    }

    function setPISmintRate(uint newRate) public auth("50%DemPreVote@STCoin") {
        PISmintRate = newRate;
    }

    function cashOut(uint amount, address dest) public auth("100%Demonstration@STCoin") {
        require(amount > 0);
        dest.transfer(amount,ASSET_PAI);
    }
}