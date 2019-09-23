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
        admin.callCreateNewRole(paiDAO,"LiqudatorContract","ADMIN",0);
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
        finance = new Finance(paiDAO,paiIssuer,setting,oracle);
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);
        admin.callAddMember(paiDAO,liquidator,"LiqudatorContract");

        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PAIMINTER");

        btcIssuer.mint(100000000000, p1);
        btcIssuer.mint(100000000000, p2);
        btcIssuer.mint(100000000000, this);
        admin.callMint(paiIssuer,100000000000,this);
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


    function testAddDebt() public {
        setup();
        assertEq(0, liquidator.totalDebt());
        bool tempBool = p1.callAddDebt(liquidator,100000000);
        assertTrue(!tempBool);
        tempBool = admin.callAddDebt(liquidator,100000000);
        assertTrue(tempBool);
        assertEq(100000000, liquidator.totalDebt());
    }

    function testAddPAI() public {
        setup();
        uint value = 1000000000;
        liquidator.transfer(value, ASSET_PAI);
        assertEq(value, liquidator.totalAssetPAI());
    }

    function testAddBTC() public {
        setup();
        uint value = 1000000000;
        liquidator.transfer(value, ASSET_BTC);
        assertEq(value, liquidator.totalCollateral());
    }

    function testCancelDebt() public {
        setup();
        uint value = 1000000000;
        //not enough pai
        liquidator.transfer(value, ASSET_PAI);
        admin.callAddDebt(liquidator,value * 2);
        liquidator.cancelDebt();
        assertEq(value, liquidator.totalDebt());

        //not enough pai in liquidator but enough pai in finance
        finance.transfer(value, ASSET_PAI);
        liquidator.cancelDebt();
        assertEq(0, liquidator.totalDebt());

        //not enough pai in neither liquidator or finance
        liquidator.transfer(value, ASSET_PAI);
        admin.callAddDebt(liquidator,value * 2);
        finance.transfer(value/2, ASSET_PAI);
        liquidator.cancelDebt();
        assertEq(value / 2, liquidator.totalDebt());

        //more than enough pai in liquidator
        liquidator.transfer(value, ASSET_PAI);
        liquidator.cancelDebt();
        assertEq(0, liquidator.totalAssetPAI()); //3
        assertEq(value/2,flow.balance(finance,ASSET_PAI));

        //not enough pai in liquidator but have some collateral
        liquidator.transfer(1000, ASSET_BTC);
        admin.callAddDebt(liquidator,value / 4);
        liquidator.cancelDebt();
        assertEq(value / 4, liquidator.totalDebt());
    }


    function testCollateralPrice() public {
        setup();
        assertEq(10 * RAY, liquidator.collateralPrice());

        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY * 5);
        p1.callUpdatePrice(oracle, RAY * 5);
        p2.callUpdatePrice(oracle, RAY * 5);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 5);
        assertEq(oracle.getPrice(), RAY * 5);
        assertEq(5 * RAY, liquidator.collateralPrice());

        admin.callTerminatePhaseOne(liquidator);
        admin.callAddDebt(liquidator,100000000);
        liquidator.transfer(100000000, ASSET_BTC);
        admin.callTerminatePhaseTwo(liquidator);
        assertEq(RAY, liquidator.collateralPrice());
    }

    function testBuyCollateralNormal() public {
        setup();
        uint btcAmount = 10000;
        uint debt = 48500;
        uint value = 9700;

        liquidator.transfer(btcAmount, ASSET_BTC);
        admin.callAddDebt(liquidator,debt);
        assertEq(btcAmount, liquidator.totalCollateral());
        assertEq(debt, liquidator.totalDebt());
        assertEq(10 * RAY, liquidator.collateralPrice());
        uint emm = flow.balance(this,ASSET_BTC);

        liquidator.buyCollateral.value(value, ASSET_PAI)();
        assertEq(1000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(liquidator.totalDebt(),debt - value);
        assertEq(liquidator.totalAssetPAI(),0);

        liquidator.buyCollateral.value(value, ASSET_PAI)();
        assertEq(2000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(liquidator.totalDebt(),debt - 2 * value);
        assertEq(liquidator.totalAssetPAI(),0);

        liquidator.buyCollateral.value(3 * value, ASSET_PAI)();
        assertEq(5000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(liquidator.totalDebt(),0);
        assertEq(liquidator.totalAssetPAI(),0);

        liquidator.buyCollateral.value(9900, ASSET_PAI)();
        assertEq(6000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(liquidator.totalDebt(),0);
        assertEq(liquidator.totalAssetPAI(),0);
        assertEq(flow.balance(finance,ASSET_PAI),9900);
    }

    function testBuyCollateralNormal2() public {
        setup();
        uint btcAmount = 10000;
        uint debt = 48500;
        uint value = 9700;

        liquidator.transfer(btcAmount, ASSET_BTC);
        admin.callAddDebt(liquidator,debt);
        assertEq(btcAmount, liquidator.totalCollateral());
        assertEq(debt, liquidator.totalDebt());
        assertEq(10 * RAY, liquidator.collateralPrice());
        uint emm = flow.balance(this,ASSET_BTC);
        uint emm2 = flow.balance(this,ASSET_PAI);

        liquidator.buyCollateral.value(5 * 9700 + 9900, ASSET_PAI)();
        assertEq(6000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(liquidator.totalDebt(),0);
        assertEq(liquidator.totalAssetPAI(),0);
        assertEq(flow.balance(finance,ASSET_PAI),9900);

        liquidator.buyCollateral.value(5 * 9900, ASSET_PAI)();
        assertEq(10000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(5 * 9700 + 5 * 9900,emm2 - flow.balance(this,ASSET_PAI));
        assertEq(liquidator.totalDebt(),0);
        assertEq(liquidator.totalAssetPAI(),0);
        assertEq(flow.balance(finance,ASSET_PAI),5 * 9900);
    }

    function testBuyCollateralNormal3() public {
        setup();
        uint btcAmount = 10000;
        uint debt = 48500;
        uint value = 9700;

        liquidator.transfer(btcAmount, ASSET_BTC);
        admin.callAddDebt(liquidator,debt);
        assertEq(btcAmount, liquidator.totalCollateral());
        assertEq(debt, liquidator.totalDebt());
        assertEq(10 * RAY, liquidator.collateralPrice());
        uint emm = flow.balance(this,ASSET_BTC);
        uint emm2 = flow.balance(this,ASSET_PAI);

        liquidator.buyCollateral.value(100000000, ASSET_PAI)();
        assertEq(10000,flow.balance(this,ASSET_BTC) - emm);
        assertEq(5 * 9700 + 5 * 9900,emm2 - flow.balance(this,ASSET_PAI));
        assertEq(liquidator.totalDebt(),0);
        assertEq(liquidator.totalAssetPAI(),0);
        assertEq(flow.balance(finance,ASSET_PAI),5 * 9900);
    }

    function testBuyCollateralFail() public {
        setup();
        uint btcAmount = 10000;
        uint debt = 48500;
        liquidator.transfer(btcAmount, ASSET_BTC);
        admin.callAddDebt(liquidator,debt);
        assertEq(btcAmount, liquidator.totalCollateral());
        assertEq(debt, liquidator.totalDebt());
        assertEq(10 * RAY, liquidator.collateralPrice());
        
        admin.callMint(paiIssuer,100000000000,p1);
        bool tempBool = p1.callBuyCollateral(liquidator,9700,ASSET_PAI);
        assertTrue(tempBool);
        admin.callGlobalShutDown(setting);
        tempBool = p1.callBuyCollateral(liquidator,9700,ASSET_PAI);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callBuyCollateral(liquidator,9700,ASSET_PAI);
        assertTrue(tempBool);
    }

    function testBuyCollateralSettlement() public {
        setup();
        liquidator.transfer(1000000000, ASSET_BTC);
        admin.callAddDebt(liquidator,50000000000);
        assertEq(1000000000, liquidator.totalCollateral());
        assertEq(50000000000, liquidator.totalDebt());
        assertEq(10 * RAY, liquidator.collateralPrice());

        uint value = 30000000000;

        admin.callTerminatePhaseOne(liquidator);
        admin.callTerminatePhaseTwo(liquidator);
        assertEq(10**27 * 500 / 10, liquidator.collateralPrice());

        liquidator.buyCollateral.value(value, ASSET_PAI)();
        assertEq(400000000, liquidator.totalCollateral());
        assertEq(0, liquidator.totalAssetPAI());

        uint emm = flow.balance(this,ASSET_PAI);
        liquidator.buyCollateral.value(value, ASSET_PAI)();
        assertEq(0, liquidator.totalCollateral());
        assertEq(0, liquidator.totalAssetPAI());
        assertEq(20000000000, emm - flow.balance(this,ASSET_PAI));
    }
}