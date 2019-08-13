pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../liquidator.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

contract LiquidatorTest is Template, DSTest, DSMath {
    Liquidator private liquidator;
    PriceOracle private oracle;
    PAIIssuer private issuer;

    uint private discount = 970000000000000000000000000;
    uint private ASSET_BTC;
    uint private ASSET_PAI;

    function() public payable {

    }

    constructor(address liq, address ora, address iss) public {
        liquidator = Liquidator(liq);
        oracle = PriceOracle(ora);
        issuer = PAIIssuer(iss);

        ASSET_BTC = 0; /// using ASIM asset for test purpose
        ASSET_PAI = issuer.getAssetType();
    }

    function debug() public view returns(uint) {
        return issuer.getAssetType();
    }

    function testAddDebt() public {
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testAddPAI() public {
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        assertEq(value, liquidator.totalAssetPAI());
    }

    function testAddBTC() public {
        uint value = 1000000000;
        liquidator.addBTC.value(value, ASSET_BTC)();
        assertEq(value, liquidator.totalCollateralBTC());
    }

    function testCancelDebtWithPAIRemaining() public {
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        liquidator.addDebt(value/2);
        assertEq(value/2, liquidator.totalAssetPAI());
    }

    function testCancelDebtWithDebtRemaining() public {
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        liquidator.addDebt(value*2);
        assertEq(value, liquidator.totalDebtPAI());
    }

    function testAddDebtAndBTC() public {
        uint value = 1000000000;
        liquidator.addBTC.value(value, ASSET_BTC)();
        assertEq(value, liquidator.totalCollateralBTC());
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testCollateralPrice() public {
        oracle.updatePrice(0, 10*(10**27));
        assertEq(10*(10**27), liquidator.collateralPrice());
    }

    //// should be tested when there is BTC in Liquidator
    //// let's say 10 BTC
    function testBuyCollateralNormal() public {

        liquidator.addBTC.value(1000000000, ASSET_BTC)();

        assertEq(1000000000, liquidator.totalCollateralBTC());

        oracle.updatePrice(0, 10*(10**27));
        assertEq(10*(10**27), liquidator.collateralPrice());

        uint value = 2000000000;

        uint originalBTC = liquidator.totalCollateralBTC();

        liquidator.buyColleteral.value(value, ASSET_PAI)();

        uint amount = rdiv(value, rmul(liquidator.collateralPrice(), discount));
        if(amount > originalBTC) {
            assertEq(0, liquidator.totalCollateralBTC());
            assertEq(rmul(originalBTC, rmul(liquidator.collateralPrice(), discount)), liquidator.totalAssetPAI());
        } else {
            assertEq(originalBTC - amount, liquidator.totalCollateralBTC());
            assertEq(0, liquidator.totalAssetPAI());
        }
    }  

    //// should be tested when there is BTC and -PAI in Liquidator
    //// let's say 10 BTC and -500 PAI
    function testBuyCollateralSettlement() public {
        liquidator.addBTC.value(1000000000, ASSET_BTC)();
        liquidator.addDebt(50000000000);

        assertEq(1000000000, liquidator.totalCollateralBTC());
        assertEq(50000000000, liquidator.totalDebtPAI());

        oracle.updatePrice(0, 10**27 * 10);
        assertEq(10**27 * 10, liquidator.collateralPrice());

        uint value = 2000000000;

        uint originalBTC = liquidator.totalCollateralBTC();

        liquidator.settlePhaseOne();
        liquidator.settlePhaseTwo();

        assertEq(10**27 * 500 / 10, liquidator.collateralPrice());

        liquidator.buyColleteral.value(value, ASSET_PAI)();

        uint amount = rdiv(value, liquidator.collateralPrice());
        if(amount > originalBTC) {
            assertEq(0, liquidator.totalCollateralBTC());
            assertEq(rmul(originalBTC, liquidator.collateralPrice()), liquidator.totalAssetPAI());
        } else {
            assertEq(originalBTC - amount, liquidator.totalCollateralBTC());
            assertEq(0, liquidator.totalAssetPAI());
        }        
    }
}