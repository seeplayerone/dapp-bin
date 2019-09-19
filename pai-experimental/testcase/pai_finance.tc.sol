pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";




contract TestBase is Template, DSTest, DSMath {
    TimefliesTDC internal tdc;
    TimefliesCDP internal cdp;
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
    FakePAIIssuer internal paiIssuer;
    FakeBTCIssuer internal btcIssuer;
    FakePerson internal admin;
    FakePerson internal p1;
    FakePerson internal p2;
    FakePaiDao internal paiDAO;
    Setting internal setting;
    TimefliesFinance internal finance;

    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PAI;

    function() public payable {}

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
        finance = new TimefliesFinance(paiDAO,paiIssuer,setting);
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PAIMINTER");

        tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
        finance.init(tdc);

        cdp = new TimefliesCDP(paiDAO,paiIssuer,oracle,liquidator,setting,finance,100000000000);
        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,cdp,"PAIMINTER");
        admin.callAddMember(paiDAO,cdp,"BTCCDP");

        bool tempBool;
        btcIssuer.mint(200000000000, p1);
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        cdp.fly(1 years);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool); //0
        cdp.fly(1);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool); //1
        cdp.fly(1 days);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool); //2
        cdp.fly(1 years);

        //cdp.fly(0);
        // cdp.updateRates();
        // tempBool = p1.callRepay(cdp,1,500000000,ASSET_PAI);
        // assertTrue(tempBool);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);//3

        assertEq(cdp.accumulatedRates(),0);
       
        btcIssuer.mint(200000000000, p2);

    }
}

contract SettingTest is TestBase {
    function testSetPAIIssuer() public {
        setup();
        assertEq(finance.issuer(), paiIssuer);
        FakePAIIssuer issuer2 = new FakePAIIssuer("PAIISSUER2",paiDAO);
        issuer2.init();
        bool tempBool = p1.callSetPAIIssuer(finance, issuer2);
        assertTrue(!tempBool);
        tempBool = admin.callSetPAIIssuer(finance, issuer2);
        assertTrue(!tempBool);
        admin.callCashOut(finance,4400000000,p2);
        assertEq(flow.balance(finance,ASSET_PAI),0);
        tempBool = p1.callSetPAIIssuer(finance, issuer2);
        assertTrue(!tempBool);
        tempBool = admin.callSetPAIIssuer(finance, issuer2);
        assertTrue(tempBool);
        assertEq(finance.issuer(), issuer2);
        assertEq(uint(finance.ASSET_PAI()), uint(issuer2.PAIGlobalId()));
    }

    function testSetSetting() public {
        setup();
        assertEq(finance.setting(), setting);
        Setting setting2 = new Setting(paiDAO);

        bool tempBool = p1.callSetSetting(finance, setting2);
        assertTrue(!tempBool);
        tempBool = admin.callSetSetting(finance, setting2);
        assertTrue(tempBool);
        assertEq(finance.setting(), setting2);
    }


    function testSetTDC() public {
        setup();
        assertEq(finance.tdc(), tdc);

        bool tempBool = p1.callSetTDC(finance, p2);
        assertTrue(!tempBool);
        tempBool = admin.callSetTDC(finance, p2);
        assertTrue(tempBool);
        assertEq(finance.tdc(), p2);
    }
}

contract FunctionTest is TestBase {
    function testPayForInterest() public {
        setup();
        bool tempBool = p1.callPayForInterest(finance, 100, p2);
        assertTrue(!tempBool);
        tempBool = admin.callPayForInterest(finance, 100, p2);
        assertTrue(!tempBool);
        admin.callCreateNewRole(paiDAO,"TDCContract","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"TDCContract");
        tempBool = admin.callPayForInterest(finance, 100, p2);
        assertTrue(tempBool);
        assertEq(flow.balance(p2,ASSET_PAI), 100);
    }

    function testPayForDebt() public {
        setup();
        bool tempBool = p1.callPayForDebt(finance, 400000000);
        assertTrue(!tempBool);
        tempBool = admin.callPayForDebt(finance, 400000000);
        assertTrue(!tempBool);
        admin.callCreateNewRole(paiDAO,"LiqudatorContract","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"LiqudatorContract");
        tempBool = admin.callPayForDebt(finance, 400000000);
        assertTrue(tempBool);
        assertEq(flow.balance(admin,ASSET_PAI), 400000000);
        tempBool = admin.callPayForDebt(finance, 5000000000);
        assertTrue(tempBool);
        assertEq(flow.balance(admin,ASSET_PAI), 4400000000);
    }

    function testPayForDividends() public {
        setup();
        FakePerson p3 = new FakePerson();
        DividendsSample dd = new DividendsSample(p1,p2,p3,finance);
        bool tempBool = p1.callGetMoney(dd);
        assertTrue(!tempBool);
        admin.callCreateNewRole(paiDAO,"DividendsContract","ADMIN",0);
        admin.callAddMember(paiDAO,dd,"DividendsContract");
        tempBool = p1.callGetMoney(dd);
        assertTrue(tempBool);
        tempBool = p2.callGetMoney(dd);
        assertTrue(tempBool);
        tempBool = p3.callGetMoney(dd);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PAI), 10000);
        assertEq(flow.balance(p2,ASSET_PAI), 20000);
        assertEq(flow.balance(p3,ASSET_PAI), 30000);
    }

    function testAirDrop() public {
        setup();
        assertEq(finance.applyAmount(),0);
        bool tempBool = p1.callApplyForAirDropCashOut(finance,1000);
        assertTrue(!tempBool);
        assertEq(flow.balance(p2,ASSET_BTC),200000000000);
        assertEq(flow.balance(cdp,ASSET_BTC),20000000000);
        tempBool = p2.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);
        admin.callCreateNewRole(paiDAO,"AirDropAddr","ADMIN",0);
        admin.callAddMember(paiDAO,p1,"AirDropAddr");
        tempBool = p1.callApplyForAirDropCashOut(finance,1000);
        assertTrue(tempBool);
        assertEq(finance.applyAmount(),0);
        assertEq(finance.applyNonce(),1);
        assertEq(finance.applyAddr(),p1);
        assertEq(finance.applyTime(),block.timestamp);


    }
}