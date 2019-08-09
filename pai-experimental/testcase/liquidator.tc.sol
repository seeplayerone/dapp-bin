pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../liquidator.sol";
// import "../price_oracle.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/price_oracle.sol";

contract LiquidatorTest is Template, DSTest, DSMath {
    Liquidator private liquidator;
    PriceOracle private oracle;

    uint private discount = 970000000000000000000000000;

    constructor() public {
        liquidator = Liquidator(0x0);
        oracle = PriceOracle(0x0);
    }

    function testAddDebt() public {
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testAddPAI() public payable {
        liquidator.addPAI();
        assertEq(msg.value, liquidator.totalAssetPAI());
    }

    function testAddBTC() public payable {
        liquidator.addBTC();
        assertEq(msg.value, liquidator.totalCollateralBTC());
    }

    function testCancelDebtWithPAIRemaining() public payable {
        liquidator.addPAI();
        liquidator.addDebt(msg.value/2);
        assertEq(msg.value/2, liquidator.totalAssetPAI());
    }

    function testCancelDebtWithDebtRemaining() public payable {
        liquidator.addPAI();
        liquidator.addDebt(msg.value*2);
        assertEq(msg.value, liquidator.totalDebtPAI());
    }

    function testAddDebtAndBTC() public payable {
        liquidator.addBTC();
        assertEq(msg.value, liquidator.totalCollateralBTC());
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testCollateralPrice() public {
        oracle.updatePrice(0, 10*(10**27));
        assertEq(10*(10**27), liquidator.collateralPrice());
    }

    //// should be tested when there is BTC in Liquidator
    //// let's say 10 BTC
    function testBuyCollateralNormal() public payable {
        assertEq(1000000000, liquidator.totalCollateralBTC());

        oracle.updatePrice(0, 10*(10**27));
        assertEq(10*(10**27), liquidator.collateralPrice());

        uint originalBTC = liquidator.totalCollateralBTC();

        liquidator.buyColleteral();

        uint amount = rdiv(msg.value, rmul(liquidator.collateralPrice(), discount));
        if(amount > originalBTC) {
            assertEq(0, liquidator.totalCollateralBTC());
            assertEq(rmul(originalBTC, rmul(liquidator.collateralPrice(), discount)), liquidator.totalAssetPAI());
        } else {
            assertEq(originalBTC - amount, liquidator.totalCollateralBTC());
            assertEq(rmul(amount, rmul(liquidator.collateralPrice(), discount)), liquidator.totalAssetPAI());
        }
    }
}