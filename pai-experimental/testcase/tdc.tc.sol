pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";


contract TestBase is Template, DSTest, DSMath {
    TimefliesTDC internal tdc;
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
        finance = new Finance(paiIssuer); // todo
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PAIMINTER");

        tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);

        btcIssuer.mint(100000000000, p1);
        btcIssuer.mint(100000000000, p2);
        btcIssuer.mint(100000000000, this);
        admin.callMint(paiIssuer,100000000000,p1);
        admin.callMint(paiIssuer,100000000000,p2);
        admin.callMint(paiIssuer,100000000000,this);
    }
}

contract SettingTest is TestBase {
    function testUpdateBaseInterestRate() public {
        setup();
        assertEq(tdc.baseInterestRate(), RAY / 5);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 12 / 1000);
        admin.callUpdateDepositRate(setting, RAY / 10);
        assertEq(tdc.baseInterestRate(), RAY / 5);
        assertTrue(p1.callUpdateBaseInterestRate(tdc));
        assertEq(tdc.baseInterestRate(), RAY / 10);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 12 / 1000);
    }

    function testUpdateFloatUp() public {
        setup();
        assertEq(tdc.floatUp(0), RAY * 4 / 1000);
        assertEq(tdc.floatUp(1), RAY * 6 / 1000);
        assertEq(tdc.floatUp(2), RAY * 8 / 1000);
        assertEq(tdc.floatUp(3), RAY * 10 / 1000);
        assertEq(tdc.floatUp(4), RAY * 12 / 1000);
        assertEq(tdc.floatUp(5), 0);
        assertEq(tdc.floatUp(6), 0);
        assertEq(tdc.floatUp(7), 0);
        assertEq(tdc.floatUp(8), 0);
        assertEq(tdc.floatUp(9), 0);
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 12 / 1000);
        bool tempBool = p1.callUpdateFloatUp(tdc,0,RAY * 2 / 1000);
        assertTrue(!tempBool);
        for(uint8 i = 0 ; i < 10; i++) {
            admin.callUpdateFloatUp(tdc,i,RAY * 2 / 1000);
            assertEq(tdc.floatUp(i), RAY * 2 / 1000);
        }
        admin.callUpdateFloatUp(tdc,0, RAY * 8 / 1000);
        admin.callUpdateFloatUp(tdc,1, RAY * 12 / 1000);
        admin.callUpdateFloatUp(tdc,2, RAY * 16 / 1000);
        admin.callUpdateFloatUp(tdc,3, RAY * 20 / 1000);
        admin.callUpdateFloatUp(tdc,4, RAY * 24 / 1000);

        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY / 5 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY / 5 + RAY * 12 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY / 5 + RAY * 16 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY / 5 + RAY * 20 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY / 5 + RAY * 24 / 1000);
        tempBool = admin.callUpdateFloatUp(tdc,10,RAY * 2 / 1000);
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

    function testSwitchDeposit() public {
        setup();
        assertTrue(!tdc.disableDeposit());
        bool tempBool = p1.callSwitchDeposit(tdc,true);
        assertTrue(!tempBool);
        tempBool = admin.callSwitchDeposit(tdc,true);
        assertTrue(tempBool);
        assertTrue(tdc.disableDeposit());
        admin.callSwitchDeposit(tdc,false);
        assertTrue(!tdc.disableDeposit());
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
        assertEq(tdc.baseInterestRate(), RAY / 5);
        Setting setting2 = new Setting(paiDAO);
        admin.callUpdateDepositRate(setting2, RAY / 10);

        bool tempBool = p1.callSetSetting(tdc, setting2);
        assertTrue(!tempBool);
        tempBool = admin.callSetSetting(tdc, setting2);
        assertTrue(tempBool);
        assertEq(tdc.setting(), setting2);
        assertEq(tdc.baseInterestRate(), RAY / 10);
    }

    function testSetPAIIssuer() public {
        setup();
        assertEq(tdc.issuer(), paiIssuer);
        FakePAIIssuer issuer2 = new FakePAIIssuer("PAIISSUER2",paiDAO);
        issuer2.init();
        bool tempBool = p1.callSetPAIIssuer(tdc, issuer2);
        assertTrue(!tempBool);
        tempBool = admin.callSetPAIIssuer(tdc, issuer2);
        assertTrue(tempBool);
        assertEq(tdc.issuer(), issuer2);
        assertEq(uint(tdc.ASSET_PAI()), uint(issuer2.PAIGlobalId()));
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

        admin.callSwitchDeposit(tdc,true);
        tempBool = p1.callTDCDeposit(tdc,0,1000,ASSET_PAI);
        assertTrue(!tempBool);
        admin.callSwitchDeposit(tdc,false);
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

    // function testReturnMoney() public {
    //     setup();
    //     uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
    //     bool tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
    //     assertTrue(!tempBool); //0
    //     tdc.fly(30 days);
    //     assertTrue(tdc.checkMaturity(idx)); //1
    //     tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
    //     assertTrue(!tempBool); //2
    //     assertEq(flow.balance(finance,ASSET_PAI),0); // 3
    //     finance.transfer(100000,ASSET_PAI);
    //     assertEq(flow.balance(finance,ASSET_PAI),100000); //4
    //     uint emm = flow.balance(this,ASSET_PAI);
    //     tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
    //     assertTrue(tempBool); //5
    //     assertEq(flow.balance(this,ASSET_PAI) - emm, 10167);//6
    //     tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
    //     assertTrue(!tempBool);//7
    // }

    function testReturnMoney() public {
        setup();
        uint idx = 1;
        p1.callTDCDeposit(tdc,0,10000,ASSET_PAI);
        bool tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(!tempBool); //0
        tdc.fly(30 days);
        assertTrue(tdc.checkMaturity(idx)); //1
        tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(!tempBool); //2
        assertEq(flow.balance(finance,ASSET_PAI),0); // 3
        finance.transfer(100000,ASSET_PAI);
        assertEq(flow.balance(finance,ASSET_PAI),100000); //4
        //uint emm = flow.balance(p1,ASSET_PAI);
        tempBool = p2.callReturnMoney(tdc,idx);
        assertTrue(tempBool); //5
        // assertEq(flow.balance(p1,ASSET_PAI) - emm, 10167);//6
        // tempBool = p2.callReturnMoney(tdc,idx);
        // assertTrue(!tempBool);//7
    }
}






//     function testInterestCalculate() public {
//         setup();
//         assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY * 204 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY * 206 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY * 208 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY * 210 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY * 212 / 1000);

//         tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
//         tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
//         tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
//         tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
//         tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
//         tdc.fly(360 days);
//         uint emm1 = flow.balance(this,ASSET_PAI);
//         uint emm2 = flow.balance(tdc,ASSET_PAI);
//         uint emm3 = flow.balance(finance,ASSET_PAI);
//         tdc.returnMoney(1);
//         assertEq(flow.balance(this,ASSET_PAI) - emm1, 10167);
//         assertEq(emm2 - flow.balance(tdc,ASSET_PAI), 10000);
//         assertEq(emm3 - flow.balance(finance,ASSET_PAI),167);


//         emm1 = flow.balance(this,ASSET_PAI);
//         emm2 = flow.balance(tdc,ASSET_PAI);
//         emm3 = flow.balance(finance,ASSET_PAI);
//         tdc.returnMoney(2);
//         assertEq(flow.balance(this,ASSET_PAI) - emm1,10338);
//         assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
//         assertEq(emm3 - flow.balance(finance,ASSET_PAI),338);

//         emm1 = flow.balance(this,ASSET_PAI);
//         emm2 = flow.balance(tdc,ASSET_PAI);
//         emm3 = flow.balance(finance,ASSET_PAI);
//         tdc.returnMoney(3);
//         assertEq(flow.balance(this,ASSET_PAI) - emm1,10512);
//         assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
//         assertEq(emm3 - flow.balance(finance,ASSET_PAI),512);

//         emm1 = flow.balance(this,ASSET_PAI);
//         emm2 = flow.balance(tdc,ASSET_PAI);
//         emm3 = flow.balance(finance,ASSET_PAI);
//         tdc.returnMoney(4);
//         assertEq(flow.balance(this,ASSET_PAI) - emm1,11035);
//         assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
//         assertEq(emm3 - flow.balance(finance,ASSET_PAI),1035);

//         emm1 = flow.balance(this,ASSET_PAI);
//         emm2 = flow.balance(tdc,ASSET_PAI);
//         emm3 = flow.balance(finance,ASSET_PAI);
//         tdc.returnMoney(5);
//         assertEq(flow.balance(this,ASSET_PAI) - emm1,12090);
//         assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);
//         assertEq(emm3 - flow.balance(finance,ASSET_PAI),2090);
//     }
// }