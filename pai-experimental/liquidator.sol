pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_finance.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";

contract Liquidator is DSMath, DSNote, Template, ACLSlave {

    uint96 public ASSET_COLLATERAL;
    uint96 public ASSET_PAI;

    uint public totalDebt; /// total debt of the liquidator
    uint public discount1; /// collateral selling discount when debt > 0
    uint public discount2; /// collateral selling discount when debt = 0

    bool private settlementP1; /// the business is in settlement stage
    bool private settlementP2; /// the business is in settlement stage and all CDPs have been liquidated
    uint private settlementPrice; /// collateral settlement price, avaliable on settlememnt phase 2

    PriceOracle public priceOracle; /// price oracle
    PAIIssuer public issuer; /// PAI issuer
    string public CDP_NAME;///identify different cdps
    Finance public finance; ///finance contract
    Setting public setting;

    constructor(
        address paiMainContract,
        address _oracle,
        address _issuer,
        string cdpName,
        address _finance,
        address _setting
        ) public {
        master = ACLMaster(paiMainContract);
        priceOracle = PriceOracle(_oracle);
        ASSET_COLLATERAL = priceOracle.ASSET_COLLATERAL();
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.PAIGlobalId();
        CDP_NAME = cdpName;
        finance = Finance(_finance);
        setting = Setting(_setting);
        discount1 = RAY * 97 / 100;
        discount2 = RAY * 99 / 100;
    }

    /// payable fallback function
    /// the liquidator can accept all types of assets issued on Asimov
    function() public payable {

    }

    function setPAIIssuer(address newIssuer) public note auth("DIRECTORVOTE") {
        issuer = PAIIssuer(newIssuer);
        ASSET_PAI = issuer.PAIGlobalId();
    }

    function setAssetCollateral(address newPriceOracle) public note auth("DIRECTORVOTE") {
        priceOracle = PriceOracle(newPriceOracle);
        ASSET_COLLATERAL = priceOracle.ASSET_COLLATERAL();
    }

    function setDiscount1(uint value) public note auth("DIRECTORVOTE") {
        require(value <= RAY);
        discount1 = value;
    }

    function setDiscount2(uint value) public note auth("DIRECTORVOTE") {
        require(value <= RAY);
        discount2 = value;
    }

    /// total earned PAI
    /// in the current design, stability fees in CDP are sent to liquidator
    function totalAssetPAI() public view returns (uint256) {
        return flow.balance(this, ASSET_PAI);
    }

    /// total collateral in BTC'
    function totalCollateral() public view returns (uint256) {
        return flow.balance(this, ASSET_COLLATERAL);
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI
    function cancelDebt() public note {
        if (totalAssetPAI() >= totalDebt) {
            if (totalDebt > 0) {
                issuer.burn.value(totalDebt, ASSET_PAI)();
                totalDebt = 0;
            }
            if(totalAssetPAI() > 0) {
                finance.transfer(totalAssetPAI(), ASSET_PAI);
            }
            return;
        }
        if (!settlementP1 && totalCollateral() == 0)
            finance.payForDebt(sub(totalDebt,totalAssetPAI()));
        uint256 amount = min(totalAssetPAI(), totalDebt);
        if(amount > 0) {
            totalDebt = sub(totalDebt, amount);
            issuer.burn.value(amount, ASSET_PAI)();
        }
    }

    /// BTC' price against PAI
    function collateralPrice() public view returns (uint256) {
        return settlementP2 ? settlementPrice : priceOracle.getPrice();
    }

    /// the liquidator sells BTC'
    /// users can buy collateral from the liquidator either before settlement or in settlement phase 2, with different prices
    function buyCollateral() public payable note {
        require(setting.globalOpen());
        require(msg.assettype == ASSET_PAI);
        require(!settlementP1 || settlementP2);
        require(totalCollateral() > 0);
        if(0 == totalDebt) {
            buyCollateralInternal(msg.value, rmul(collateralPrice(),discount2));
            cancelDebt();
            return;
        }
        if(totalDebt > msg.value) {
            buyCollateralInternal(msg.value, rmul(collateralPrice(),discount1));
            cancelDebt();
            return;
        }
        uint change;
        uint amount1 = rdiv(totalDebt, rmul(collateralPrice(),discount1));
        if(amount1 > totalCollateral()) {
            change = sub(msg.value, rmul(totalCollateral(),rmul(collateralPrice(),discount1)));
            msg.sender.transfer(change, ASSET_PAI);
            msg.sender.transfer(totalCollateral(), ASSET_COLLATERAL);
        } else {
            uint amount2 = rdiv(sub(msg.value,totalDebt), rmul(collateralPrice(),discount2));
            if(add(amount1,amount2) > totalCollateral()) {
                change = sub(sub(msg.value, rmul(amount1,rmul(collateralPrice(),discount1))),
                                  rmul(sub(totalCollateral(),amount1),rmul(collateralPrice(),discount2)));
                msg.sender.transfer(change, ASSET_PAI);
                msg.sender.transfer(totalCollateral(), ASSET_COLLATERAL);
            } else {
                msg.sender.transfer(add(amount1,amount2), ASSET_COLLATERAL);
            }
        }
        cancelDebt();
    }

    function buyCollateralInternal(uint _money, uint _refPrice) internal {
        uint amount = rdiv(_money, _refPrice);
        require(amount > 0);
        if(amount > totalCollateral()) {
            uint change = rmul(sub(amount, totalCollateral()), _refPrice);
            msg.sender.transfer(change, ASSET_PAI);
            msg.sender.transfer(totalCollateral(), ASSET_COLLATERAL);
        } else {
            msg.sender.transfer(amount, ASSET_COLLATERAL);
        }
    }

    function addDebt(uint amount) public auth(CDP_NAME) {
        totalDebt = add(totalDebt, amount);
    }

    function terminatePhaseOne() public note auth("SettlementContract"){
        require(!settlementP1);
        settlementP1 = true;
    }

    function terminatePhaseTwo() public note auth("SettlementContract"){
        require(settlementP1);
        require(!settlementP2);
        if(flow.balance(this, ASSET_COLLATERAL) > 0) {
            settlementPrice = mul(totalDebt, RAY) / flow.balance(this, ASSET_COLLATERAL);
        }
        discount1 = RAY;
        discount2 = RAY;
        settlementP2 = true;
    }
}