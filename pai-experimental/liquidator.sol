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

    bool private settlement; /// the business is in settlement stage
    bool private allLiquidated; /// the business is in settlement stage and all CDPs have been liquidated
    uint private collateralSettlementPrice; /// collateral settlement price

    PriceOracle private oracle; /// price oracle
    PAIIssuer private issuer; /// PAI issuer

    address private hole = 0x660000000000000000000000000000000000000000;

    constructor(address _oracle, address _issuer) public {
        oracle = PriceOracle(_oracle);
        issuer = PAIIssuer(_issuer);

        ASSET_BTC = 0; /// using ASIM asset for test purpose
        ASSET_PAI = issuer.getAssetType();

        discount = 970000000000000000000000000;
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

    function debugAllValues() public view returns (uint, uint, uint) {
        return (totalAssetPAI(), totalDebtPAI(), totalCollateralBTC());
    }

    /// the liquidator needs to continuous neutralize debt with earned PAI 
    function cancelDebt() public note {
        if(totalAssetPAI() == 0 || totalDebtPAI() == 0) {
            return;
        }

        uint256 amount = min(totalAssetPAI(), totalDebtPAI());
        totalDebt = sub(totalDebt, amount);

        hole.transfer(amount, ASSET_PAI);
        issuer.burn(amount);
    }

    /// BTC' price against PAI
    function collateralPrice() public view returns (uint256) {
        ///不规范？view函数调用了一个不知道会不会需要消耗gas的方法
        return settlement ? collateralSettlementPrice : oracle.getPrice(ASSET_BTC);
    }

    /// the liquidator sells BTC'
    function buyColleteral() public payable note {
        require(msg.assettype == ASSET_PAI);
        require(!settlement||allLiquidated);
        if(!settlement){       
            buyColleteralNormal(msg.value);
        }else if(allLiquidated){
            buyColleteralSpecial(msg.value); 
        }
    }

    function buyColleteralNormal(uint _money) internal {
        uint amount = rdiv(_money, rmul(collateralPrice(), discount));
        require(amount > 0);

        if(amount > totalCollateralBTC()) {
            uint change = rmul(amount - totalCollateralBTC(), rmul(collateralPrice(), discount));
            msg.sender.transfer(change, ASSET_PAI);
            msg.sender.transfer(totalCollateralBTC(), ASSET_BTC);
        } else {
            msg.sender.transfer(amount, ASSET_BTC);
        }

        /// cancel debt with newly coming in PAI
        cancelDebt();
    }

    function buyColleteralSpecial(uint _money) internal {
        require(collateralSettlementPrice > 0);
        uint amount = rdiv(_money, collateralSettlementPrice);
        require(amount > 0);

        if(amount > totalCollateralBTC()) {
            uint change = rmul(amount - totalCollateralBTC(), collateralSettlementPrice);
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

    function settlePhaseOne() public {
        require(!settlement);
        settlement = true;
    }

    function settlePhaseTwo() public {
        require(settlement);
        require(!allLiquidated);
        ///下一语句需要改写为safemath的形式
        collateralSettlementPrice = (totalDebt * (10**27) / flow.balance(this, ASSET_BTC));
        allLiquidated = true;
    }


    /// only for debug
    function States() public view returns(bool,bool) {
        return (settlement,allLiquidated);
    }

    function reOpen() public {
       settlement = false;
       allLiquidated = false;
    }    
}