pragma solidity 0.4.25;

import "./testPrepare.sol";

contract TestBase is Template, DSTest, DSMath {
    TimefliesTDC internal tdc;
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
    TimefliesOracle internal oracle2;
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
    uint96 internal ASSET_PIS;

    function() public payable {}

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());

        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY * 10,ASSET_BTC);
        oracle2  = new TimefliesOracle("BTCOracle",paiDAO,RAY,ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"Liqudator@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",3,false);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"Settlement@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"BTCCDP","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"DirVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"50%DemPreVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"100%DemPreVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"50%Demonstration@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"100%Demonstration@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"DirPisVote","ADMIN",0,false);
        admin.callAddMember(paiDAO,admin,"BTCOracle");
        admin.callAddMember(paiDAO,p1,"BTCOracle");
        admin.callAddMember(paiDAO,p2,"BTCOracle");
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callAddMember(paiDAO,admin,"Settlement@STCoin");
        admin.callAddMember(paiDAO,admin,"DirVote@STCoin");
        admin.callAddMember(paiDAO,admin,"50%DemPreVote@STCoin");
        admin.callAddMember(paiDAO,admin,"100%DemPreVote@STCoin");
        admin.callAddMember(paiDAO,admin,"50%Demonstration@STCoin");
        admin.callAddMember(paiDAO,admin,"100%Demonstration@STCoin");
        admin.callAddMember(paiDAO,admin,"BTCCDP");
        admin.callAddMember(paiDAO,admin,"DirPisVote");
        admin.callModifyEffectivePriceNumber(oracle,3);

        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();

        setting = new Setting(paiDAO);
        finance = new Finance(paiDAO,paiIssuer,setting,oracle2);
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        admin.callCreateNewRole(paiDAO,"Minter@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,admin,"Minter@STCoin");

        tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
        admin.callCreateNewRole(paiDAO,"TDC@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,tdc,"TDC@STCoin");

        btcIssuer.mint(100000000000, p1);
        btcIssuer.mint(100000000000, p2);
        btcIssuer.mint(100000000000, this);
        admin.callMint(paiIssuer,100000000000,p1);
        admin.callMint(paiIssuer,100000000000,p2);
        admin.callMint(paiIssuer,100000000000,this);
        admin.callUpdateDepositRate(setting, RAY / 5);
        p1.callUpdateBaseInterestRate(tdc);
    }
}

contract SettingTest is TestBase {
    function testUpdateBaseInterestRate() public {
        setup();
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 12 / 1000);
        admin.callUpdateDepositRate(setting, RAY / 10);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 12 / 1000);
    }

    function testUpdateRateAdj() public {
        setup();
        assertEq(tdc.rateAdj(0), int(RAY * 4 / 1000));
        assertEq(tdc.rateAdj(1), int(RAY * 6 / 1000));
        assertEq(tdc.rateAdj(2), int(RAY * 8 / 1000));
        assertEq(tdc.rateAdj(3), int(RAY * 10 / 1000));
        assertEq(tdc.rateAdj(4), int(RAY * 12 / 1000));
        assertEq(tdc.rateAdj(5), 0);
        assertEq(tdc.rateAdj(6), 0);
        assertEq(tdc.rateAdj(7), 0);
        assertEq(tdc.rateAdj(8), 0);
        assertEq(tdc.rateAdj(9), 0);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 12 / 1000);
        bool tempBool = p1.callUpdateRateAdj(tdc,0,int(RAY * 2 / 1000));
        assertTrue(!tempBool);
        for(uint8 i = 0 ; i < 10; i++) {
            admin.callUpdateRateAdj(tdc,i,int(RAY * 2 / 1000));
            assertEq(tdc.rateAdj(i), int(RAY * 2 / 1000));
        }
        admin.callUpdateRateAdj(tdc,0, int(RAY * 8 / 1000));
        admin.callUpdateRateAdj(tdc,1, int(RAY * 12 / 1000));
        admin.callUpdateRateAdj(tdc,2, int(RAY * 16 / 1000));
        admin.callUpdateRateAdj(tdc,3, int(RAY * 20 / 1000));
        admin.callUpdateRateAdj(tdc,4, int(RAY * 24 / 1000));

        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 12 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 16 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 20 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 24 / 1000);
        tempBool = admin.callUpdateRateAdj(tdc,10,int(RAY * 2 / 1000));
        assertTrue(!tempBool);
    }

    function testUpdateTerm() public {
        setup();
        assertEq(tdc.term(0), 30 * 86400);
        assertEq(tdc.term(1), 60 * 86400);
        assertEq(tdc.term(2), 90 * 86400);
        assertEq(tdc.term(3), 180 * 86400);
        assertEq(tdc.term(4), 360 * 86400);
        assertEq(tdc.term(5), 0);
        assertEq(tdc.term(6), 0);
        assertEq(tdc.term(7), 0);
        assertEq(tdc.term(8), 0);
        assertEq(tdc.term(9), 0);
        bool tempBool = p1.callUpdateTerm(tdc,5,1 days);
        assertTrue(!tempBool);
        for(uint8 i = 5 ; i < 10; i++) {
            admin.callUpdateTerm(tdc,i,2 days);
            assertEq(tdc.term(i), 2 * 86400);
        }
        for(i = 0 ; i < 5; i++) {
            tempBool = admin.callUpdateTerm(tdc,i,2 days);
            assertTrue(!tempBool);
        }
    }

    function testChangeState() public {
        setup();
        assertTrue(tdc.enable(0));
        assertTrue(tdc.enable(1));
        assertTrue(tdc.enable(2));
        assertTrue(tdc.enable(3));
        assertTrue(tdc.enable(4));
        assertTrue(!tdc.enable(5));
        assertTrue(!tdc.enable(6));
        assertTrue(!tdc.enable(7));
        assertTrue(!tdc.enable(8));
        assertTrue(!tdc.enable(9));
        bool tempBool = p1.callChangeState(tdc,5,true);
        assertTrue(!tempBool);
        for(uint8 i = 5 ; i < 10; i++) {
            admin.callChangeState(tdc,i,true);
            assertTrue(tdc.enable(i));
        }
        for(i = 0 ; i < 5; i++) {
            admin.callChangeState(tdc,i,false);
            assertTrue(!tdc.enable(i));
        }
    }

    function testSwitchGetInterest() public {
        setup();
        assertTrue(!tdc.disableGetInterest());
        bool tempBool = p1.callSwitchGetInterest(tdc,true);
        assertTrue(!tempBool);
        tempBool = admin.callSwitchGetInterest(tdc,true);
        assertTrue(tempBool);
        assertTrue(tdc.disableGetInterest());
        admin.callSwitchGetInterest(tdc,false);
        assertTrue(!tdc.disableGetInterest());
    }

    function testSetSetting() public {
        setup();
        assertEq(tdc.setting(), setting);
        Setting setting2 = new Setting(paiDAO);
        admin.callUpdateDepositRate(setting2, RAY / 10);

        bool tempBool = p1.callSetSetting(tdc, setting2);
        assertTrue(!tempBool);
        tempBool = admin.callSetSetting(tdc, setting2);
        assertTrue(tempBool);
        assertEq(tdc.setting(), setting2);
    }

    function testSetFinance() public {
        setup();
        assertEq(tdc.issuer(), paiIssuer);
        Finance finance2 = new Finance(paiDAO,paiIssuer,setting,oracle2);
        bool tempBool = p1.callSetFinance(tdc, finance2);
        assertTrue(!tempBool);
        tempBool = admin.callSetFinance(tdc, finance2);
        assertTrue(tempBool);
        assertEq(tdc.finance(), finance2);
    }

}

contract FunctionTest is TestBase {
    function testDeposit() public {
        setup();
        bool tempBool;
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_BTC);
        assertTrue(!tempBool);
        uint emm = flow.balance(p1,ASSET_PAI);
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(tempBool);

        (TDC.TDCType tdcType,address owner, uint principal,uint interestRate,uint time,uint principalPayed) = tdc.TDCRecords(1);
        assertEq(owner,p1);
        assertEq(uint(tdcType),0);
        assertEq(principal,1000);
        assertEq(interestRate, RAY/5 + RAY * 4 / 1000);
        assertEq(time,block.timestamp);
        assertEq(principalPayed,0);
        assertEq(flow.balance(p1,ASSET_PAI), emm - 1000);
    }

    function testDepositFail() public {
        setup();
        bool tempBool;
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(tempBool);
        admin.callGlobalShutDown(setting);
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(tempBool);

        admin.callChangeState(tdc,0,false);
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(!tempBool);
        tempBool = p1.callTDCDeposit(tdc,6,1000,ASSET_PAI);
        assertTrue(!tempBool);
        admin.callChangeState(tdc,6,true);
        tempBool = p1.callTDCDeposit(tdc,6,1000,ASSET_PAI);
        assertTrue(tempBool);
    }

    function testWithdraw() public {
        setup();
        bool tempBool;
        tempBool = p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        assertTrue(tempBool);
        (,,uint principal,,,) = tdc.TDCRecords(1);
        assertEq(principal, 10000);
        tempBool = p1.callTDCWithdraw(tdc,1,5000);
        (,,principal,,,) = tdc.TDCRecords(1);
        assertEq(principal, 5000);

        tempBool = p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        assertTrue(tempBool);//3
        tempBool = p2.callTDCWithdraw(tdc,2,5000);
        assertTrue(!tempBool);
        uint emm = flow.balance(p1,ASSET_PAI);
        tempBool = p1.callTDCWithdraw(tdc,2,5000);
        assertTrue(tempBool);
        (,,principal,,,) = tdc.TDCRecords(2);
        assertEq(principal, 5000);
        assertEq(flow.balance(p1,ASSET_PAI),emm + 5000);
        tempBool = p1.callTDCWithdraw(tdc,2,5001);
        assertTrue(!tempBool);
        tempBool = p1.callTDCWithdraw(tdc,2,5000);
        assertTrue(tempBool);
        (,,principal,,,) = tdc.TDCRecords(2);
        assertEq(principal, 0);
        assertEq(flow.balance(p1,ASSET_PAI),emm + 10000);

        tempBool = p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        assertTrue(tempBool);
        tdc.fly(30 days);
        tempBool = p1.callTDCWithdraw(tdc,3,5000);
        assertTrue(tempBool);
        uint principalPayed;
        (,,principal,,,principalPayed) = tdc.TDCRecords(3);
        assertEq(principal,10000);
        assertEq(principalPayed,5000);
        tempBool = p1.callTDCWithdraw(tdc,3,6000);
        assertTrue(!tempBool);
    }

    function testWithdrawFail() public {
        setup();
        p1.callTDCDeposit(tdc,0,1000000,ASSET_PAI);

        bool tempBool;
        tempBool = p1.callTDCWithdraw(tdc,1,100);
        assertTrue(tempBool);
        admin.callGlobalShutDown(setting);
        tempBool = p1.callTDCWithdraw(tdc,1,100);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callTDCWithdraw(tdc,1,100);
        assertTrue(tempBool);
    }

    function testAboutTime() public {
        setup();
        p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        (,,,,uint startTime1,) = tdc.TDCRecords(1);
        uint passedTime = tdc.passedTime(1);
        assertEq(passedTime,0);
        tdc.fly(100);
        (,,,,uint startTime2,) = tdc.TDCRecords(1);
        assertEq(startTime1,startTime2);
        passedTime = tdc.passedTime(1);
        assertEq(passedTime,100);

        assertTrue(!tdc.checkMaturity(1000));
        uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(90 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(180 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(360 days);
        assertTrue(tdc.checkMaturity(idx));
    }

    function testReturnMoney() public {
        setup();
        uint idx = 1;
        p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        tdc.fly(30 days);
        bool tempBool;
        assertTrue(tdc.checkMaturity(idx));
        tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(!tempBool);
        assertEq(flow.balance(finance,ASSET_PAI),0);
        finance.transfer(100000,ASSET_PAI);
        assertEq(flow.balance(finance,ASSET_PAI),100000);

        uint emm = flow.balance(p1,ASSET_PAI);
        tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PAI) - emm, 10167);
        tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(!tempBool);
    }

    function testReturnMoneyFail() public {
        setup();
        finance.transfer(10000000000,ASSET_PAI);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.fly(30 days);

        bool tempBool;
        admin.callGlobalShutDown(setting);
        tempBool = p2.callReturnMoney(tdc,1);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p2.callReturnMoney(tdc,1);
        assertTrue(tempBool);

        admin.callSwitchGetInterest(tdc,true);
        tempBool = p2.callReturnMoney(tdc,2);
        assertTrue(!tempBool);
        admin.callSwitchGetInterest(tdc,false);
        tempBool = p2.callReturnMoney(tdc,2);
        assertTrue(tempBool);

    }

    function testInterestCalculate() public {
        setup();
        finance.transfer(10000000000,ASSET_PAI);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY * 204 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY * 206 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY * 208 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY * 210 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY * 212 / 1000);

        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
        tdc.fly(360 days);
        uint emm1 = flow.balance(this,ASSET_PAI);
        uint emm2 = flow.balance(tdc,ASSET_PAI);
        uint emm3 = flow.balance(finance,ASSET_PAI);
        tdc.returnMoney(1);
        assertEq(flow.balance(this,ASSET_PAI) - emm1, 10167);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI), 10000);
        assertEq(emm3 - flow.balance(finance,ASSET_PAI),167);


        emm1 = flow.balance(this,ASSET_PAI);
        emm2 = flow.balance(tdc,ASSET_PAI);
        emm3 = flow.balance(finance,ASSET_PAI);
        tdc.returnMoney(2);
        assertEq(flow.balance(this,ASSET_PAI) - emm1,10338);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
        assertEq(emm3 - flow.balance(finance,ASSET_PAI),338);

        emm1 = flow.balance(this,ASSET_PAI);
        emm2 = flow.balance(tdc,ASSET_PAI);
        emm3 = flow.balance(finance,ASSET_PAI);
        tdc.returnMoney(3);
        assertEq(flow.balance(this,ASSET_PAI) - emm1,10512);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
        assertEq(emm3 - flow.balance(finance,ASSET_PAI),512);

        emm1 = flow.balance(this,ASSET_PAI);
        emm2 = flow.balance(tdc,ASSET_PAI);
        emm3 = flow.balance(finance,ASSET_PAI);
        tdc.returnMoney(4);
        assertEq(flow.balance(this,ASSET_PAI) - emm1,11035);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
        assertEq(emm3 - flow.balance(finance,ASSET_PAI),1035);

        emm1 = flow.balance(this,ASSET_PAI);
        emm2 = flow.balance(tdc,ASSET_PAI);
        emm3 = flow.balance(finance,ASSET_PAI);
        tdc.returnMoney(5);
        assertEq(flow.balance(this,ASSET_PAI) - emm1,12090);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
        assertEq(emm3 - flow.balance(finance,ASSET_PAI),2090);
    }
}