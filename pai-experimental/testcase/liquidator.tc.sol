pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";



contract TestBase is Template, DSTest, DSMath {
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
    FakePAIIssuer internal paiIssuer;
    FakeBTCIssuer internal btcIssuer;
    FakePerson internal admin;
    FakePerson internal p1;
    FakePerson internal p2;
    FakePaiDao internal paiDAO;
    Setting internal setting;
    Finance internal finance;

    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PAI;

    function() public payable {

    }

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());

        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY * 10,ASSET_BTC);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",3);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"SettlementContract","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"BTCCDP","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"BTCOracle");
        admin.callAddMember(paiDAO,p1,"BTCOracle");
        admin.callAddMember(paiDAO,p2,"BTCOracle");
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callAddMember(paiDAO,admin,"SettlementContract");
        admin.callAddMember(paiDAO,admin,"BTCCDP");

        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();

        setting = new Setting(paiDAO);
        finance = new Finance(paiIssuer); // todo
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PAIMINTER");

        btcIssuer.mint(100000000000, p1);
        btcIssuer.mint(100000000000, p2);
        btcIssuer.mint(100000000000, this);
        admin.callMint(paiIssuer,100000000000,p2);
    }
}

contract LiquidatorTest is TestBase {
    function testSetPAIIssuer() public {
        setup();
        assertEq(liquidator.issuer(), paiIssuer);
        FakePAIIssuer issuer2 = new FakePAIIssuer("PAIISSUER2",paiDAO);
        issuer2.init();
        bool tempBool = p1.callSetPAIIssuer(liquidator, issuer2);
        assertTrue(!tempBool);
        tempBool = admin.callSetPAIIssuer(liquidator, issuer2);
        assertTrue(tempBool);
        assertEq(liquidator.issuer(), issuer2);
        assertEq(uint(liquidator.ASSET_PAI()), uint(issuer2.PAIGlobalId()));
    }

    function testSetAssetCollateral() public {
        setup();
        assertEq(uint(liquidator.ASSET_COLLATERAL()),uint(ASSET_BTC));
        assertEq(liquidator.priceOracle(),oracle);
        TimefliesOracle oracle2 = new TimefliesOracle("BTCOracle",paiDAO,RAY,uint96(123));
        bool tempBool = p1.callSetAssetCollateral(liquidator,oracle2);
        assertTrue(!tempBool);
        tempBool = admin.callSetAssetCollateral(liquidator,oracle2);
        assertTrue(tempBool);
        assertEq(uint(liquidator.ASSET_COLLATERAL()),123);
        assertEq(liquidator.priceOracle(),oracle2);
    }
    
    function testSetDiscount() public {
        setup();
        assertEq(liquidator.discount1(), RAY * 97 / 100);
        assertEq(liquidator.discount2(), RAY * 99 / 100);
        bool tempBool = p1.callSetDiscount1(liquidator,RAY / 2);
        assertTrue(!tempBool);
        tempBool = p1.callSetDiscount2(liquidator, RAY / 4);
        assertTrue(!tempBool);
        tempBool = admin.callSetDiscount1(liquidator, RAY / 2);
        assertTrue(tempBool);
        tempBool = admin.callSetDiscount2(liquidator, RAY / 4);
        assertTrue(tempBool);
        assertEq(liquidator.discount1(), RAY / 2);
        assertEq(liquidator.discount2(), RAY / 4);
    }


    // function testAddDebt() public {
    //     setup();
    //     liquidator.addDebt(100000000);
    //     assertEq(100000000, liquidator.totalDebtPAI());
    // }

    // function testAddPAI() public {
    //     setup();
    //     uint value = 1000000000;
    //     liquidator.addPAI.value(value, ASSET_PAI)();
    //     assertEq(value, liquidator.totalAssetPAI());
    // }

    // function testAddBTC() public {
    //     setup();
    //     uint value = 1000000000;
    //     liquidator.addBTC.value(value, ASSET_BTC)();
    //     assertEq(value, liquidator.totalCollateralBTC());
    // }

    // function testCancelDebtWithPAIRemaining() public {
    //     setup();
    //     uint value = 1000000000;
    //     liquidator.addPAI.value(value, ASSET_PAI)();
    //     liquidator.addDebt(value/2);
    //     assertEq(value/2, liquidator.totalAssetPAI());
    // }

    // function testCancelDebtWithDebtRemaining() public {
    //     setup();
    //     uint value = 1000000000;
    //     liquidator.addPAI.value(value, ASSET_PAI)();
    //     liquidator.addDebt(value*2);
    //     assertEq(value, liquidator.totalDebtPAI());
    // }

    // function testAddDebtAndBTC() public {
    //     setup();
    //     uint value = 1000000000;
    //     liquidator.addBTC.value(value, ASSET_BTC)();
    //     assertEq(value, liquidator.totalCollateralBTC());
    //     liquidator.addDebt(100000000);
    //     assertEq(100000000, liquidator.totalDebtPAI());
    // }

    // function testCollateralPrice() public {
    //     setup();
    //     oracle.updatePrice(ASSET_BTC, 10*(10**27));
    //     assertEq(10*(10**27), liquidator.collateralPrice());
    // }

    // function testBuyCollateralNormal() public {
    //     setup();
    //     liquidator.addBTC.value(1000000000, ASSET_BTC)();
    //     liquidator.addDebt(50000000000);
    
    //     assertEq(1000000000, liquidator.totalCollateralBTC());
    //     assertEq(50000000000, liquidator.totalDebtPAI());

    //     oracle.updatePrice(ASSET_BTC, 10*(10**27));
    //     assertEq(10*(10**27), liquidator.collateralPrice());

    //     uint value = 2000000000;

    //     uint originalBTC = liquidator.totalCollateralBTC();

    //     liquidator.buyCollateral.value(value, ASSET_PAI)();

    //     uint amount = rdiv(value, rmul(liquidator.collateralPrice(), discount));
    //     if(amount > originalBTC) {
    //         assertEq(0, liquidator.totalCollateralBTC());
    //         assertEq(rmul(originalBTC, rmul(liquidator.collateralPrice(), discount)), liquidator.totalAssetPAI());
    //     } else {
    //         assertEq(originalBTC - amount, liquidator.totalCollateralBTC());
    //         assertEq(0, liquidator.totalAssetPAI());
    //     }
    // }  

    // function testBuyCollateralSettlement() public {
    //     setup();
    //     liquidator.addBTC.value(1000000000, ASSET_BTC)();
    //     liquidator.addDebt(50000000000);

    //     assertEq(1000000000, liquidator.totalCollateralBTC());
    //     assertEq(50000000000, liquidator.totalDebtPAI());

    //     oracle.updatePrice(ASSET_BTC, 10**27 * 10);
    //     assertEq(10**27 * 10, liquidator.collateralPrice());

    //     uint value = 2000000000;

    //     uint originalBTC = liquidator.totalCollateralBTC();

    //     liquidator.terminatePhaseOne();
    //     liquidator.terminatePhaseTwo();

    //     assertEq(10**27 * 500 / 10, liquidator.collateralPrice());

    //     liquidator.buyCollateral.value(value, ASSET_PAI)();

    //     uint amount = rdiv(value, liquidator.collateralPrice());
    //     if(amount > originalBTC) {
    //         assertEq(0, liquidator.totalCollateralBTC());
    //         assertEq(rmul(originalBTC, liquidator.collateralPrice()), liquidator.totalAssetPAI());
    //     } else {
    //         assertEq(originalBTC - amount, liquidator.totalCollateralBTC());
    //         assertEq(0, liquidator.totalAssetPAI());
    //     }        
    // }
}