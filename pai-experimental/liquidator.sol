pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_finance.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";

contract Liquidator is DSMath, DSNote, Template, ACLSlave {

    uint96 public ASSET_COLLATERAL;
    uint96 public ASSET_PAI;

    uint public totalDebt; /// total debt of the liquidator
    uint public discount1; /// collateral selling discount when debt > 0
    uint public discount2; /// collateral selling discount when debt = 0

    bool private settlementP1; /// the business is in settlement stage
    bool private settlementP2; /// the business is in settlement stage and all CDPs have been liquidated
    uint private settlementPrice; /// collateral settlement price, avaliable on settlememnt phase 2

    PriceOracle public oracle; /// price oracle
    PAIIssuer public issuer; /// PAI issuer
    CDP public cdp;///cdp contract
    Finance public finance; ///finance contract

    constructor(address paiMainContract, address _oracle, address _issuer, address _cdp, address _finance) public {
        master = ACLMaster(paiMainContract);
        oracle = PriceOracle(_oracle);
        ASSET_COLLATERAL = priceOracle.ASSET_COLLATERAL();
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.PAIGlobalId();
        cdp = CDP(_cdp);
        finance = Finance(_finance);
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

    // /// total debt in PAI
    // /// once a CDP record is liquidated, total debt increases
    // function totalDebtPAI() public view returns (uint256) {
    //     return totalDebt;
    // }

    /// total collateral in BTC'
    function totalCollateralBTC() public view returns (uint256) {
        return flow.balance(this, ASSET_BTC);
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI
    function cancelDebt() public note {
        if (0 == totalDebt) {
            if (totalAssetPAI() > 0)
                finance.transfer(totalAssetPAI(), ASSET_PAI);
            return;
        }
        if (totalAssetPAI() < totalDebt)
            finance.payForDebt(sub(totalDebt,totalAssetPAI()));
        uint256 amount = min(totalAssetPAI(), totalDebt);
        totalDebt = sub(totalDebt, amount);
        issuer.burn.value(amount, ASSET_PAI)();
    }

    /// BTC' price against PAI
    function collateralPrice() public view returns (uint256) {
        return settlementP2 ? settlementPrice : oracle.getPrice();
    }

    /// the liquidator sells BTC'
    /// users can buy collateral from the liquidator either before settlement or in settlement phase 2, with different prices
    function buyCollateral() public payable note {
        require(msg.assettype == ASSET_PAI);
        require(!settlementP1 || settlementP2);
        cancelDebt();
        uint amount1;
        uint amount2;
        if (totalDebt > 0) {
            if (msg.value > totalDebt) {
                amount
            }
        }
        /// before settlement
        if(!settlementP1){
            uint referencePrice = rmul(collateralPrice(), discount);
            buyCollateralInternal(msg.value, referencePrice);
        }
        /// settlement phase 2
        else if(settlementP2){
            require(settlementPrice > 0);
            buyCollateralInternal(msg.value, settlementPrice);
        }
    }

    function buyCollateralInternal(uint _money, uint _refPrice) internal {
        uint amount = rdiv(_money, _refPrice);
        require(amount > 0);

        if(amount > totalCollateralBTC()) {
            uint change = rmul(sub(amount, totalCollateralBTC()), _refPrice);
            msg.sender.transfer(change, ASSET_PAI);
            msg.sender.transfer(totalCollateralBTC(), ASSET_BTC);
        } else {
            msg.sender.transfer(amount, ASSET_BTC);
        }

        /// cancel debt with newly coming in PAI
        cancelDebt();
    }

    function addDebt(uint amount) public {
        require(msg.sender == cdp);
        totalDebt = add(totalDebt, amount);
        cancelDebt();
    }

    function terminatePhaseOne() public {
        require(!settlementP1);
        settlementP1 = true;
    }

    function terminatePhaseTwo() public {
        require(settlementP1);
        require(!settlementP2);
        if(flow.balance(this, ASSET_BTC) > 0)
            settlementPrice = mul(totalDebt, RAY) / flow.balance(this, ASSET_BTC);
        discount1 = RAY;
        discount2 = RAY;
        settlementP2 = true;
    }
}