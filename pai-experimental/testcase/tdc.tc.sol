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
        admin.callMint(paiIssuer,100000000000,this);
    }
}

contract SettingTest is TestBase {
    function testUpdateBaseInterestRate() public {
        setup();
        assertEq(tdc.baseInterestRate(), RAY / 5);
        admin.callUpdateDepositRate(setting, RAY / 10);
        assertEq(tdc.baseInterestRate(), RAY / 5);
        assertTrue(p1.callUpdateBaseInterestRate(tdc));
        assertEq(tdc.baseInterestRate(), RAY / 10);
    }
}
//     function testSetRate() public {
//         setup();
//         assertEq(tdc.baseInterestRate(), RAY / 5);
//         tdc.updateBaseInterestRate(RAY / 10);
//         assertEq(tdc.baseInterestRate(), RAY / 10);
//         assertEq(tdc.floatUp(0),RAY * 4 / 1000);
//         assertEq(tdc.floatUp(1),RAY * 6 / 1000);
//         assertEq(tdc.floatUp(2),RAY * 8 / 1000);
//         assertEq(tdc.floatUp(3),RAY * 10 / 1000);
//         assertEq(tdc.floatUp(4),RAY * 12 / 1000);

//         assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 4 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 6 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 8 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 10 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 12 / 1000);

//         tdc.updateFloatUp(TDC.TDCType._30DAYS, RAY * 8 / 1000);
//         tdc.updateFloatUp(TDC.TDCType._60DAYS, RAY * 12 / 1000);
//         tdc.updateFloatUp(TDC.TDCType._90DAYS, RAY * 16 / 1000);
//         tdc.updateFloatUp(TDC.TDCType._180DAYS, RAY * 20 / 1000);
//         tdc.updateFloatUp(TDC.TDCType._360DAYS, RAY * 24 / 1000);

//         assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 8 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 12 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 16 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 20 / 1000);
//         assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 24 / 1000);
//     }

//     function testDeposit() public {
//         setup();
//         FakePerson p1 = new FakePerson();
//         paiIssuer.mint(100000000, p1);
//         paiIssuer2.mint(100000000, p1);
//         bool tempBool;
//         tempBool = p1.callDeposit(tdc,0,1000,uint96(FAKE_PAI));
//         assertTrue(!tempBool);
//         tempBool = p1.callDeposit(tdc,0,1000,uint96(ASSET_PAI));
//         assertTrue(tempBool);

//         (TDC.TDCType tdcType,address owner, uint principal,uint interestRate,uint time) = tdc.TDCRecords(1);
//         assertEq(owner,p1);
//         assertEq(uint(tdcType),0);
//         assertEq(principal,1000);
//         assertEq(interestRate, RAY/5 + RAY * 4 / 1000);
//         assertEq(time,block.timestamp);
//         assertEq(flow.balance(p1,ASSET_PAI), 100000000 - 1000);
//     }

//     function testWithdraw() public {
//         setup();
//         uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
//         (,,uint principal,,) = tdc.TDCRecords(idx);
//         assertEq(principal, 10000);
//         tdc.withdraw(idx,5000);
//         (,,principal,,) = tdc.TDCRecords(idx);
//         assertEq(principal, 5000);

//         FakePerson p1 = new FakePerson();
//         paiIssuer.mint(10000, p1);
//         bool tempBool;
//         tempBool = p1.callDeposit(tdc,0,10000,uint96(ASSET_PAI));
//         assertTrue(tempBool);
//         assertEq(flow.balance(p1,ASSET_PAI),0);
//         FakePerson p2 = new FakePerson();
//         tempBool = p2.callWithdraw(tdc,2,5000);
//         assertTrue(!tempBool);
//         tempBool = p1.callWithdraw(tdc,2,5000);
//         assertTrue(tempBool);
//         (,,principal,,) = tdc.TDCRecords(2);
//         assertEq(principal, 5000);
//         assertEq(flow.balance(p1,ASSET_PAI),5000);
//         tempBool = p1.callWithdraw(tdc,2,5001);
//         assertTrue(!tempBool);
//         tempBool = p1.callWithdraw(tdc,2,5000);
//         assertTrue(tempBool);
//         (,,principal,,) = tdc.TDCRecords(2);
//         assertEq(principal, 0);
//         assertEq(flow.balance(p1,ASSET_PAI),10000);
//     }

//     function testAboutTime() public {
//         setup();
//         uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
//         (,,,,uint startTime1) = tdc.TDCRecords(idx);
//         uint passedTime = tdc.passedTime(idx);
//         assertEq(passedTime,0);
//         tdc.fly(100);
//         (,,,,uint startTime2) = tdc.TDCRecords(idx);
//         assertEq(startTime1,startTime2);
//         passedTime = tdc.passedTime(idx);
//         assertEq(passedTime,100);

//         assertTrue(!tdc.checkMaturity(1000));
//         idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(30 days);
//         assertTrue(tdc.checkMaturity(idx));
//         idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(30 days);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(30 days);
//         assertTrue(tdc.checkMaturity(idx));
//         idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(90 days);
//         assertTrue(tdc.checkMaturity(idx));
//         idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(180 days);
//         assertTrue(tdc.checkMaturity(idx));
//         idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
//         assertTrue(!tdc.checkMaturity(idx));
//         tdc.fly(360 days);
//         assertTrue(tdc.checkMaturity(idx));
//     }

//     function testReturnMoney() public {
//         setup();
//         uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
//         uint emm = flow.balance(this,ASSET_PAI);
//         bool tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
//         assertTrue(!tempBool);
//         tdc.fly(30 days);
//         tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
//         assertTrue(tempBool);
//         assertEq(flow.balance(this,ASSET_PAI),emm + 10167);
//         tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
//         assertTrue(!tempBool);
//     }

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