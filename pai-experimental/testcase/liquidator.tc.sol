pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../liquidator.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

contract FakeTemplateNamePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract LiquidatorTest is Template, DSTest, DSMath {
    Liquidator private liquidator;
    PriceOracle private oracle;
    FakeTemplateNamePAIIssuer private issuer;

    uint private discount = 970000000000000000000000000;
    uint private ASSET_BTC;
    uint private ASSET_PAI;

    function() public payable {

    }

    constructor() public payable {
        /// Please send me 100 BTC
    }

    function setup() public {
        ASSET_BTC = 0; /// using ASIM asset for test purpose
        
        oracle = new PriceOracle();
        oracle.updatePrice(ASSET_BTC, RAY * 10);

        issuer = new FakeTemplateNamePAIIssuer();
        issuer.init("sb");
        ASSET_PAI = issuer.getAssetType();

        liquidator = new Liquidator(oracle, issuer);

        issuer.mint(100000000000, this);
    }

    function debug() public view returns(uint) {
        return issuer.getAssetType();
    }

    function testAddDebt() public {
        setup();
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testAddPAI() public {
        setup();
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        assertEq(value, liquidator.totalAssetPAI());
    }

    function testAddBTC() public {
        setup();
        uint value = 1000000000;
        liquidator.addBTC.value(value, ASSET_BTC)();
        assertEq(value, liquidator.totalCollateralBTC());
    }

    function testCancelDebtWithPAIRemaining() public {
        setup();
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        liquidator.addDebt(value/2);
        assertEq(value/2, liquidator.totalAssetPAI());
    }

    function testCancelDebtWithDebtRemaining() public {
        setup();
        uint value = 1000000000;
        liquidator.addPAI.value(value, ASSET_PAI)();
        liquidator.addDebt(value*2);
        assertEq(value, liquidator.totalDebtPAI());
    }

    function testAddDebtAndBTC() public {
        setup();
        uint value = 1000000000;
        liquidator.addBTC.value(value, ASSET_BTC)();
        assertEq(value, liquidator.totalCollateralBTC());
        liquidator.addDebt(100000000);
        assertEq(100000000, liquidator.totalDebtPAI());
    }

    function testCollateralPrice() public {
        setup();
        oracle.updatePrice(0, 10*(10**27));
        assertEq(10*(10**27), liquidator.collateralPrice());
    }

    //// should be tested when there is BTC in Liquidator
    //// let's say 10 BTC
    function testBuyCollateralNormal() public {
        setup();
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
        setup();
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