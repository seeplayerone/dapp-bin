pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "./3rd/note.sol";
// import "./price_oracle.sol";
// import "./pai_issuer.sol";
// import "./infra/template.sol";

import "github.com/seeplayerone/dapp-bin/library/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/3rd/note.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/3rd/pai_issuer.sol";
import "github.com/seeplayerone/dapp-bin/library/3rd/price_oracle.sol";


contract Liquidator is DSMath, DSNote, Template {

    uint private BTC_ASSET_TYPE;
    uint private PAI_ASSET_TYPE;

    /// all are calculated in RAY
    uint private totalDebt;
    uint private discount;

    bool private settlement; /// the business is in settlement stage
    uint private collateralSettlementPrice; /// collateral settlement price

    PriceOracle private priceOracle;
    PAIIssuer private issuer;

    address private hole = 0x000000000000000000000000000000000000000000;

    constructor() public {
        priceOracle = PriceOracle(0x63bd360bf9f7ca684d4ef2dc4f6a48886521d6dd4a);
        issuer = PAIIssuer(0x6311aa4aaa3db18313877616ad980b251401445be8);

        BTC_ASSET_TYPE = 0;
        PAI_ASSET_TYPE = issuer.getAssetType();

        discount = 970000000000000000000000000;
    }

    /// payable fallback function
    /// the liquidator can accept all types of assets issued on Asimov
    function() public payable {
        /// cancel debt whenever PAI comes to the liquidator
        if(msg.assettype == PAI_ASSET_TYPE) {
            cancelDebt();
        } else if(msg.assettype == BTC_ASSET_TYPE) {

        }
    }

    /// total earned PAI 
    /// in the current design, stability fees in CDP are sent to liquidator
    function totalEarnedPAI() public view returns (uint256) {
        satoshiToRay(flow.balance(this, PAI_ASSET_TYPE));
    }

    /// total debt in PAI
    /// once a CDP record is liquidated, total debt increases
    function totalDebtPAI() public view returns (uint256) {
        return totalDebt;
    }

    /// total collateral in BTC'
    function totalCollateralBTC() public view returns (uint256) {
        satoshiToRay(flow.balance(this, BTC_ASSET_TYPE));
    }

    function addDebt(uint amount) public {
        totalDebt = add(totalDebt, amount);
        cancelDebt();
    }

    function debugAllValues() public view returns (uint, uint, uint) {
        return (totalEarnedPAI(), totalDebtPAI(), totalCollateralBTC());
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI 
    /// it is invoked whenever selling collateral or PIS
    function cancelDebt() public note {
        if(totalEarnedPAI() == 0 || totalDebtPAI() == 0) {
            return;
        }

        uint256 amount = min(totalEarnedPAI(), totalDebtPAI());
        totalDebt = sub(totalDebt, amount);

        hole.transfer(rayToSatoshi(amount), PAI_ASSET_TYPE);
    }

    /// BTC' price against PAI
    function collateralPrice() public view returns (uint256){
        return priceOracle.getPrice(BTC_ASSET_TYPE);
    }

    /// PIS price against PAI
    function PISPrice() public view returns (uint256) {
        return priceOracle.getPrice(PAI_ASSET_TYPE);
    }

    /// the liquidator sells BTC'
    /// the liquidator can sell all the BTC'
    function buyColleteral() public payable note {
        require(!settlement);
        require(msg.assettype == PAI_ASSET_TYPE);

        /// TODO need to consider the case where amount > totalCollateral()
        /// in which we should transfer the changes to msg.sender as we deal with repay in cdp
        uint amount = rdiv(satoshiToRay(msg.value), rmul(collateralPrice(), discount));
        require(amount > 0);

        if(amount > totalCollateralBTC()) {
            // uint change = rmul(amount - totalCollateralBTC(), rmul(collateralPrice(), discount));
            // msg.sender.transfer(rayToSatoshi(change), PAI_ASSET_TYPE);
            msg.sender.transfer(totalCollateralBTC(), BTC_ASSET_TYPE);
        } else {
            msg.sender.transfer(rayToSatoshi(amount), BTC_ASSET_TYPE);
        }

        /// cancel debt with newly coming in PAI
        cancelDebt();
    }

    function deposit() public payable note {
        if(msg.assettype == PAI_ASSET_TYPE) {
            cancelDebt();
        } else if(msg.assettype == BTC_ASSET_TYPE) {

        }
    }

    function settle(uint price) public {
        require(!settlement);
        settlement = true;
        collateralSettlementPrice = price;
    }

    function satoshiToRay(uint amount) public pure returns (uint) {
        return mul(amount, 10**19);
    }

    function rayToSatoshi(uint rayAmount) public pure returns (uint) {
        return rayAmount / 10**19;
    }
    
}