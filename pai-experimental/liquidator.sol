pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "./3rd/note.sol";
// import "./price_oracle.sol";
// import "./pai_issuer.sol";
// import "../library/template.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";

contract Liquidator is DSMath, DSNote, Template {

    uint private ASSET_BTC;
    uint private ASSET_PAI;

    uint private totalDebt; /// total debt of the liquidator
    uint private discount; /// collateral selling discount

    bool private settlementP1; /// the business is in settlement stage
    bool private settlementP2; /// the business is in settlement stage and all CDPs have been liquidated
    uint private settlementPrice; /// collateral settlement price, avaliable on settlememnt phase 2

    PriceOracle private oracle; /// price oracle
    PAIIssuer private issuer; /// PAI issuer

    constructor(address _oracle, address _issuer) public {
        oracle = PriceOracle(_oracle);
        issuer = PAIIssuer(_issuer);

        ASSET_BTC = 0;
        ASSET_PAI = issuer.getAssetType();

        discount = 970000000000000000000000000;
    }

    function setAssetPAI(uint assetType) public {
        ASSET_PAI = assetType;
    } 

    function setAssetBTC(uint assetType) public {
        ASSET_BTC = assetType;
    }

    function setDiscount(uint value) public {
        discount = value;
    }

    function getDiscount() public view returns (uint) {
        return discount;
    }

    /// payable fallback function
    /// the liquidator can accept all types of assets issued on Asimov
    function() public payable {

    }

    /// total earned PAI 
    /// in the current design, stability fees in CDP are sent to liquidator
    function totalAssetPAI() public view returns (uint256) {
        return flow.balance(this, ASSET_PAI);
    }

    /// total debt in PAI
    /// once a CDP record is liquidated, total debt increases
    function totalDebtPAI() public view returns (uint256) {
        return totalDebt;
    }

    /// total collateral in BTC'
    function totalCollateralBTC() public view returns (uint256) {
        return flow.balance(this, ASSET_BTC);
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI 
    function cancelDebt() public note {
        if(totalAssetPAI() == 0 || totalDebtPAI() == 0) {
            return;
        }

        uint256 amount = min(totalAssetPAI(), totalDebtPAI());
        totalDebt = sub(totalDebt, amount);

        issuer.burn.value(amount, ASSET_PAI)();
    }

    /// BTC' price against PAI
    function collateralPrice() public view returns (uint256) {
        return settlementP2 ? settlementPrice : oracle.getPrice(ASSET_BTC);
    }

    /// the liquidator sells BTC'
    /// users can buy collateral from the liquidator either before settlement or in settlement phase 2, with different prices
    function buyCollateral() public payable note {
        require(msg.assettype == ASSET_PAI);
        require(!settlementP1 || settlementP2);
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

    function addBTC() public payable note {
        require(msg.assettype == ASSET_BTC);
    }

    function addPAI() public payable note {
        require(msg.assettype == ASSET_PAI);
        cancelDebt();
    }

    function addDebt(uint amount) public {
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
        settlementP2 = true;
    }
}