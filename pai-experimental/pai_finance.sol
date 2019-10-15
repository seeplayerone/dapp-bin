pragma solidity 0.4.25;

import "../library/template.sol";
import "./pai_issuer.sol";
import "../library/acl_slave.sol";
import "./3rd/math.sol";
import "./pai_setting.sol";
import "./pai_main.sol";
import "./price_oracle.sol";

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
        issuer = PAIIssuer(_issuer);
        setting = Setting(_setting);
        ASSET_PAI = issuer.PAIGlobalId();
        priceOracle = PriceOracle(_oracle);
        ASSET_PIS = priceOracle.ASSET_COLLATERAL();
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
        uint CashOutLimit = mul(delta,add(setting.depositInterestRate(),setting.currentDepositFloatUp()));
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

    /// @dev 所有的设置都需要在构造函数里面进行配置，方便初始化部署
    function setSafePad(uint amount) public auth("PISVOTE") {
        safePad = amount;
    }

    function setPISmintRate(uint newRate) public auth("PISVOTE") {
        PISmintRate = newRate;
    }

    function cashOut(uint amount, address dest) public auth("PISVOTE") {
        require(amount > 0);
        dest.transfer(amount,ASSET_PAI);
    }
}