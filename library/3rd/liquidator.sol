pragma solidity 0.4.25;

import "./math.sol";
import "./note.sol";
import "./price_oracle.sol";

contract Liquidator is DSMath, DSNote {

    uint private BTC_ASSET_TYPE;
    uint private PAI_ASSET_TYPE;

    uint private totalDebt;
    uint private discount;

    bool private settlement; /// the business is in settlement stage
    uint private collateralSettlementPrice; /// collateral settlement price

    PriceOracle private priceOracle;

    /// payable fallback function
    /// the liquidator can accept all types of assets issued on Asimov
    constructor() public payable {
        /// cancel debt whenever PAI comes to the liquidator
        if(msg.assettype == PAI_ASSET_TYPE) {
            cancelDebt();
        }
    }

    /// total earned PAI 
    /// in the current design, stability fees in CDP are sent to liquidator
    function totalEarnedPAI() public pure returns (uint256) {
        /// TODO flow.balanceOf(this, PAI_ASSET_TYPE);
        return 1;
    }

    /// total debt in PAI
    /// once a CDP record is liquidated, total debt increases
    function totalDebtPAI() public view returns (uint256) {
        return totalDebt;
    }

    /// total collateral in BTC'
    function totalCollateral() public pure returns (uint256) {
        /// TODO flow.balanceOf(this, BTC_ASSET_TYPE);
        return 1;
    }

    function addDebt(uint amount) public {
        totalDebt = add(totalDebt, amount);
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI 
    /// it is invoked whenever selling collateral or PIS
    function cancelDebt() public note {
        if(totalEarnedPAI() == 0 || totalDebtPAI() == 0) {
            return;
        }

        uint256 amount = min(totalEarnedPAI(), totalDebtPAI());
        totalDebt = sub(totalDebt, amount);
        /// TODO destory `amount` of PAI utxo - PAI Issuer should take care of this
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
    function sellColleteral() public payable note {
        require(!settlement);
        require(msg.assettype == PAI_ASSET_TYPE);

        /// TODO need to consider the case where amount > totalCollateral()
        /// in which we should transfer the changes to msg.sender as we deal with repay in cdp
        uint amount = rdiv(msg.value, rmul(collateralPrice(), discount));
        require(amount > 0);

        if(amount > totalCollateral()) {
            uint change = rmul(amount - totalCollateral(), rmul(collateralPrice(), discount));
            msg.sender.transfer(totalCollateral(), BTC_ASSET_TYPE);
            msg.sender.transfer(change, PAI_ASSET_TYPE);
        } else {
            msg.sender.transfer(amount, BTC_ASSET_TYPE);
        }

        /// cancel debt with newly coming in PAI
        cancelDebt();
    }

    /// once the BTC' is sold out and `totalDebtPAI()` > `totalEarnedPAI()`
    /// PIS can be mint to clear the debt (totalDebtPAI() - totalEarnedPAI())
    function sellPIS() public payable note {
        require(!settlement);
        require(msg.assettype == PAI_ASSET_TYPE);
        
        /// only mint PIS when there is no collateral in the stock and debt is not cleared
        require(totalCollateral() == 0 && totalDebtPAI() > 0);
        
        require(msg.value <= totalDebtPAI());

        uint amount;
        if(msg.value > totalDebtPAI()) {
            amount = rdiv(totalDebtPAI(), rmul(PISPrice(), discount));
            msg.sender.transfer(sub(msg.value, totalDebtPAI()), PAI_ASSET_TYPE);

        } else {
            amount = rdiv(msg.value, rmul(PISPrice(), discount));
            /// TODO mint and transfer amount of PAI to msg.sender
        }

        /// cancel debt with newly coming in PAI
        cancelDebt();
    }

    function settle(uint price) public {
        require(!settlement);
        settlement = true;
        collateralSettlementPrice = price;
    }


    
}