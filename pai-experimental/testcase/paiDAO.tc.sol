pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";

contract TestBase is Template, DSTest, DSMath {
    event printString(string);
    event printDoubleString(string,string);
    event printAddr(string,address);
    event printNumber(uint);
    event printAddrs(string,address[]);
    //others
    FakeBTCIssuer internal btcIssuer;
    FakeBTCIssuer internal ethIssuer;

    //MAIN
    FakePaiDao internal paiDAO;
    FakePAIIssuer internal paiIssuer;
    //vote1
    //vote2
    //vote3
    TimefliesOracle internal pisOracle;
    Setting internal setting;
    Finance internal finance;

    //BTC LENDING
    TimefliesOracle internal btcOracle;
    Liquidator internal btcLiquidator;
    TimefliesCDP internal btcCDP;
    Settlement internal btcSettlement;

    //ETH LENDING
    TimefliesOracle internal ethOracle;
    Liquidator internal ethLiquidator;
    TimefliesCDP internal ethCDP;
    Settlement internal ethSettlement;

    //PAI DEPOSIT
    TimefliesTDC internal tdc;

    //fake person
    FakePerson internal admin;
    FakePerson internal oracle1;
    FakePerson internal oracle2;
    FakePerson internal oracle3;
    FakePerson internal airDropRobot;
    FakePerson internal CFO;

    //asset
    uint96 internal ASSET_BTC;
    uint96 internal ASSET_ETH;
    uint96 internal ASSET_PIS;
    uint96 internal ASSET_PAI;

    function() public payable {

    }

    function setup() public {
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());
        ethIssuer = new FakeBTCIssuer();
        ethIssuer.init("ETH");
        ASSET_ETH = uint96(btcIssuer.getAssetType());

        admin = new FakePerson();
        oracle1 = new FakePerson();
        oracle2 = new FakePerson();
        oracle3 = new FakePerson();
        airDropRobot = new FakePerson();
        CFO = new FakePerson();

        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callChangeTopAdmin(paiDAO,"PISVOTE");
        admin.callChangeSuperior(paiDAO,"PISVOTE","PISVOTE");
        admin.callRemoveMember(paiDAO,admin,"ADMIN");

        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        pisOracle = new TimefliesOracle("PISOracle", paiDAO, RAY * 100, ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"PISOracle","PISVOTE",3);
        admin.callAddMember(paiDAO,oracle1,"PISOracle");
        admin.callAddMember(paiDAO,oracle2,"PISOracle");
        admin.callAddMember(paiDAO,oracle3,"PISOracle");
        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();
        setting = new Setting(paiDAO);
        finance = new Finance(paiDAO,paiIssuer,setting,pisOracle);
        admin.callCreateNewRole(paiDAO,"AirDropAddr","PISVOTE",0);
        admin.callCreateNewRole(paiDAO,"CFO","PISVOTE",0);
        admin.callAddMember(paiDAO,airDropRobot,"AirDropAddr");
        admin.callAddMember(paiDAO,CFO,"CFO");
        admin.callCreateNewRole(paiDAO,"FinanceContract","PISVOTE",0);
        admin.callAddMember(paiDAO,finance,"FinanceContract");

        btcOracle = new TimefliesOracle("BTCOracle", paiDAO, RAY * 70000, ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"BTCOracle","PISVOTE",3);
        admin.callAddMember(paiDAO,oracle1,"BTCOracle");
        admin.callAddMember(paiDAO,oracle2,"BTCOracle");
        admin.callAddMember(paiDAO,oracle3,"BTCOracle");
        btcLiquidator = new Liquidator(paiDAO,btcOracle, paiIssuer,"BTCCDP",finance,setting);
        btcCDP = new TimefliesCDP(paiDAO,paiIssuer,btcOracle,btcLiquidator,setting,finance,100000000000);
        admin.callCreateNewRole(paiDAO,"PAIMINTER","PISVOTE",0);
        admin.callAddMember(paiDAO,btcCDP,"PAIMINTER");
        admin.callCreateNewRole(paiDAO,"BTCCDP","PISVOTE",0);
        admin.callAddMember(paiDAO,btcCDP,"BTCCDP");
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","PISVOTE",0);
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);
        btcSettlement = new Settlement(paiDAO,btcOracle,btcCDP,btcLiquidator);
        admin.callCreateNewRole(paiDAO,"SettlementContract","PISVOTE",0);
        admin.callAddMember(paiDAO,btcSettlement,"SettlementContract");

        ethOracle = new TimefliesOracle("ETHOracle", paiDAO, RAY * 1500, ASSET_ETH);
        admin.callCreateNewRole(paiDAO,"ETHOracle","PISVOTE",3);
        admin.callAddMember(paiDAO,oracle1,"ETHOracle");
        admin.callAddMember(paiDAO,oracle2,"ETHOracle");
        admin.callAddMember(paiDAO,oracle3,"ETHOracle");
        ethLiquidator = new Liquidator(paiDAO,ethOracle,paiIssuer,"ETHCDP",finance,setting);
        ethCDP = new TimefliesCDP(paiDAO,paiIssuer,ethOracle,ethLiquidator,setting,finance,30000000000);
        admin.callAddMember(paiDAO,ethCDP,"PAIMINTER");
        admin.callAddMember(paiDAO,ethCDP,"ETHCDP");
        admin.callUpdateRatioLimit(setting, ASSET_ETH, RAY * 3 / 10);
        ethSettlement = new Settlement(paiDAO,ethOracle,ethCDP,ethLiquidator);
        admin.callAddMember(paiDAO,ethSettlement,"SettlementContract");

        tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
        admin.callSetTDC(finance, tdc);

        admin.callMint(paiDAO,1000000000000,this);
        admin.callRemoveMember(paiDAO,admin,"PISVOTE");
    }

    function print() public {
        setup();
        uint groupNumber = paiDAO.indexOfACL();
        for (uint i = 1; i <= groupNumber; i++) {
            emit printString("===================================================");
            emit printDoubleString("Role:",string(paiDAO.roles(i)));
            emit printDoubleString("Superior:",string(paiDAO.getSuperior(paiDAO.roles(i))));
            emit printAddrs("members:",paiDAO.getMembers(paiDAO.roles(i)));
        }
        emit printString("===================================================");
        emit printAddr("paiDAO",paiDAO);
        emit printAddr("paiIssuer",paiIssuer);
        emit printAddr("pisOracle",pisOracle);
        emit printAddr("setting",setting);
        emit printAddr("finance",finance);
        emit printAddr("btcOracle",btcOracle);
        emit printAddr("btcLiquidator",btcLiquidator);
        emit printAddr("btcCDP",btcCDP);
        emit printAddr("btcSettlement",btcSettlement);
        emit printAddr("ethOracle",ethOracle);
        emit printAddr("ethLiquidator",ethLiquidator);
        emit printAddr("ethCDP",ethCDP);
        emit printAddr("ethSettlement",ethSettlement);
        emit printAddr("tdc",tdc);
        emit printAddr("Admin",admin);
        emit printAddr("oracle1",oracle1);
        emit printAddr("oracle2",oracle2);
        emit printAddr("oracle3",oracle3);
        emit printAddr("airDropRobot",airDropRobot);
        emit printAddr("CFO",CFO);
    }
}

contract TestCase is TestBase {
    function VoteSetAssetCollateral() public {
        setup();
    }

}

// contract TestCase is Template, DSTest, DSMath {
//     function() public payable {

//     }

//     function testMainContract() public {
//         FakePaiDao paiDAO;
//         uint96 ASSET_PIS;
//         uint96 ASSET_PAI;
//         bool tempBool;
//         FakePerson p1 = new FakePerson();
//         FakePerson p2 = new FakePerson();
//         FakePerson p3 = new FakePerson();
//         FakePerson p4 = new FakePerson();

//         ///test init
//         paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
//         assertEq(paiDAO.tempAdmin(),p1);//0
//         tempBool = p2.callInit(paiDAO);
//         assertTrue(tempBool);//1
//         tempBool = p2.callInit(paiDAO);
//         assertTrue(!tempBool);//2
//         tempBool = p1.callInit(paiDAO);
//         assertTrue(!tempBool);//3

//         ///test mint
//         tempBool = p1.callTempMintPIS(paiDAO,100000000,p3);
//         assertTrue(tempBool);//4
//         (,ASSET_PIS) = paiDAO.Token(0);
//         assertEq(flow.balance(p3,ASSET_PIS),100000000);//5
//         tempBool = p2.callTempMintPIS(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//6

//         ///test auth setting
//         tempBool = p3.callMintPIS(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//7
//         tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,0);
//         assertTrue(tempBool);//8
//         tempBool = p3.callMintPIS(paiDAO,100000000,p3);
//         assertTrue(tempBool);//9
//         assertEq(flow.balance(p3,ASSET_PIS),200000000);//10
//         tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,1);
//         assertTrue(tempBool);//11
//         tempBool = p3.callMintPIS(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//12

//         ///test all by order
//         tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,0);
//         assertTrue(tempBool);//13
//         tempBool = p1.callConfigFunc(paiDAO,"TESTAUTH1",p2,0);
//         assertTrue(!tempBool);//14
//         tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH1",p2,0);
//         assertTrue(tempBool);//15
//         tempBool = paiDAO.canPerform(p2,"TESTAUTH1");
//         assertTrue(tempBool);//16
//         tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH1",p2,1);
//         assertTrue(tempBool);//17
//         tempBool = paiDAO.canPerform(p2,"TESTAUTH1");
//         assertTrue(!tempBool);//18

//         tempBool = p1.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",0);
//         assertTrue(!tempBool);//19
//         tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",0);
//         assertTrue(tempBool);//20
//         tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH2"));
//         assertTrue(tempBool);//21
//         tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",1);
//         assertTrue(tempBool);//22
//         tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH2"));
//         assertTrue(!tempBool);//23

//         tempBool = p3.callTempConfig(paiDAO,"TESTAUTH3",p4,0);
//         assertTrue(!tempBool);//24
//         tempBool = p1.callTempConfig(paiDAO,"TESTAUTH3",p4,0);
//         assertTrue(tempBool);//25
//         tempBool = paiDAO.canPerform(p4,"TESTAUTH3");
//         assertTrue(tempBool);//26
//         tempBool = p1.callTempConfig(paiDAO,"TESTAUTH3",p4,1);
//         assertTrue(tempBool);//27
//         tempBool = paiDAO.canPerform(p4,"TESTAUTH3");
//         assertTrue(!tempBool);//28

//         tempBool = p3.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",0);
//         assertTrue(!tempBool);//29
//         tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",0);
//         assertTrue(tempBool);//30
//         tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH4"));
//         assertTrue(tempBool);//31
//         tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",1);
//         assertTrue(tempBool);//32
//         tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH4"));
//         assertTrue(!tempBool);//33

//         /// mintPIS and tempMintPIS are already tested

//         tempBool = p1.callMintPAI(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//34
//         tempBool = p3.callMintPAI(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//35
//         tempBool = p1.callTempConfig(paiDAO,"ISSURER",p3,0);
//         assertTrue(tempBool);//36
//         tempBool = p3.callMintPAI(paiDAO,100000003,p3);
//         assertTrue(tempBool);//37
//         (,ASSET_PAI) = paiDAO.Token(1);
//         assertEq(flow.balance(p3,ASSET_PAI),100000003);//38

//         uint balance;
//         (,,,,,balance) = paiDAO.getAssetInfo(1);
//         assertEq(balance,100000003);//39
//         (,,,,,balance) = paiDAO.getAssetInfo(0);
//         assertEq(balance,200000000);//40
//         assertEq(flow.balance(p3,ASSET_PIS),200000000);//41
//         p3.callBurn(paiDAO,100000000,ASSET_PIS);
//         assertEq(flow.balance(p3,ASSET_PIS),100000000);//42
//         (,,,,,balance) = paiDAO.getAssetInfo(0);
//         assertEq(balance,100000000);//43
//         assertEq(flow.balance(p3,ASSET_PAI),100000003);//44
//         p3.callBurn(paiDAO,100000000,ASSET_PAI);
//         assertEq(flow.balance(p3,ASSET_PAI),3);//45
//         (,,,,,balance) = paiDAO.getAssetInfo(1);
//         assertEq(balance,3);//46

//         tempBool = p3.callEveryThingIsOk(paiDAO);
//         assertTrue(!tempBool);//47
//         tempBool = p1.callEveryThingIsOk(paiDAO);
//         assertTrue(tempBool);//48
//         tempBool = p1.callTempMintPIS(paiDAO,100000000,p3);
//         assertTrue(!tempBool);//49
//         tempBool = p1.callTempConfig(paiDAO,"TESTDELETE",p4,0);
//         assertTrue(!tempBool);//50
//         tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTDELETE",0);
//         assertTrue(!tempBool);//51
//     }
    
//     function testBurn() public {
//         FakePaiDao paiDAO1;
//         FakePaiDao paiDAO2;
//         uint96 ASSET_PIS1;
//         uint96 ASSET_PIS2;
//         FakePerson p1 = new FakePerson();
//         FakePerson p2 = new FakePerson();
//         paiDAO1 = FakePaiDao(p1.createPAIDAO("DAO1"));
//         paiDAO2 = FakePaiDao(p1.createPAIDAO("DAO2"));
//         bool tempBool;
//         paiDAO1.init();
//         paiDAO2.init();
//         tempBool = p1.callTempMintPIS(paiDAO1,100000000,p2);
//         assertTrue(tempBool); //0
//         (,ASSET_PIS1) = paiDAO1.Token(0);
//         tempBool = p1.callTempMintPIS(paiDAO2,100000000,p2);
//         assertTrue(tempBool); //1
//         (,ASSET_PIS2) = paiDAO2.Token(0);
//         tempBool = p2.callBurn(paiDAO1,100,ASSET_PIS1);
//         assertTrue(tempBool); //2
//         tempBool = p2.callBurn(paiDAO2,100,ASSET_PIS2);
//         assertTrue(tempBool); //3
//         tempBool = p2.callBurn(paiDAO1,100,ASSET_PIS2);
//         assertTrue(!tempBool); //4
//         tempBool = p2.callBurn(paiDAO2,100,ASSET_PIS1);
//         assertTrue(!tempBool); //5
//     }

//     function testVoteManager() public {
//         FakePaiDao paiDAO;
//         PISVoteManager voteManager;
//         TimefliesVoteSP voteContract;
//         uint96 ASSET_PIS;
//         bool tempBool;
//         FakePerson p1 = new FakePerson();

//         ///test init
//         paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
//         tempBool = p1.callInit(paiDAO);
//         tempBool = p1.callTempMintPIS(paiDAO,100000000,p1);
//         (,ASSET_PIS) = paiDAO.Token(0);
//         voteManager = new PISVoteManager(paiDAO);
//         voteContract = new TimefliesVoteSP(paiDAO);
//         assertEq(voteManager.paiDAO(),paiDAO);//0
//         assertEq(uint(voteManager.voteAssetGlobalId()),uint(ASSET_PIS));//1

//         ///test deposit && withdraw
//         p1.callDeposit(voteManager,40000000,ASSET_PIS);
//         assertEq(voteManager.balanceOf(p1),40000000);//2
//         assertEq(flow.balance(p1,ASSET_PIS),60000000);//3
//         tempBool = p1.callWithdraw(voteManager,60000000);
//         assertTrue(!tempBool);//4
//         tempBool = p1.callWithdraw(voteManager,40000000);
//         assertTrue(tempBool);//5
//         assertEq(flow.balance(p1,ASSET_PIS),100000000);//6

//         ///test vote
//         p1.callDeposit(voteManager,40000000,ASSET_PIS);
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
//         assertTrue(!tempBool);//7
//         tempBool = p1.callTempConfig(paiDAO,"VoteManager",voteManager,0);
//         assertTrue(tempBool);//8
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
//         assertTrue(!tempBool);//9
//         tempBool = p1.callTempConfig(paiDAO,"VOTEMANAGER",voteManager,0);
//         assertTrue(tempBool);//10
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
//         assertTrue(tempBool);//11
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE2",3,paiDAO,hex"e51ed97d",hex"",20000000);
//         assertTrue(tempBool);//12
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE3",2,paiDAO,hex"e51ed97d",hex"",30000000);
//         assertTrue(tempBool);//13
//         uint mostVote;
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,30000000);//14
//         voteContract.fly(2);
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,30000000);//15
//         assertEq(voteManager.balanceOf(p1),40000000);
//         tempBool = p1.callWithdraw(voteManager,40000000);
//         assertTrue(!tempBool);//16
//         tempBool = p1.callWithdraw(voteManager,20000000);
//         assertTrue(!tempBool);//17
//         tempBool = p1.callWithdraw(voteManager,10000000);
//         assertTrue(tempBool);//18
//         voteContract.fly(1);
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,20000000);//19
//         tempBool = p1.callWithdraw(voteManager,10000000);
//         assertTrue(tempBool);//20
//         voteContract.fly(1);
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,10000000);//21
//         tempBool = p1.callWithdraw(voteManager,10000000);
//         assertTrue(tempBool);//22
//         voteContract.fly(1);
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,0);//23
//         tempBool = p1.callWithdraw(voteManager,10000000);
//         assertTrue(tempBool);//24
//         tempBool = p1.callDeposit(voteManager,40000000,ASSET_PIS);
//         assertTrue(tempBool);//25
//         tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE3",2,paiDAO,hex"e51ed97d",hex"",15000000);
//         assertTrue(tempBool);//26
//         tempBool = p1.callVoteTo(voteManager,voteContract,4,true,15000000);
//         assertTrue(tempBool);//27
//         (mostVote,) = voteManager.getMostVote(p1);
//         assertEq(mostVote,30000000);//28
//     }

//     function testBuissness() public {
//         FakePaiDao paiDAO;
//         bool tempBool;
//         FakePerson p1 = new FakePerson();
//         FakePerson p2 = new FakePerson();
//         FakePerson p3 = new FakePerson();

//         paiDAO = FakePaiDao(p3.createPAIDAO("PAIDAO"));
//         paiDAO.init();
//         TestPaiDAO bussineesContract = new TestPaiDAO(paiDAO);
//         assertEq(bussineesContract.states(),0);//0
//         tempBool = p1.callFunc1(bussineesContract);
//         assertTrue(!tempBool);//1
//         p3.callTempConfig(paiDAO,"DIRECTOR",p1,0);
//         tempBool = p1.callFunc1(bussineesContract);
//         assertTrue(tempBool);//2
//         assertEq(bussineesContract.states(),1);//3
//         tempBool = p1.callFunc2(bussineesContract);
//         assertTrue(!tempBool);//4
//         p3.callTempConfig(paiDAO,"VOTE",p2,0);
//         tempBool = p2.callFunc2(bussineesContract);
//         assertTrue(tempBool);//5
//         tempBool = p2.callFunc3(bussineesContract);
//         assertTrue(tempBool);//6
//         assertEq(bussineesContract.states(),6);//7
//         tempBool = p1.callFunc4(bussineesContract);
//         assertTrue(!tempBool);//8
//         p3.callTempOthersConfig(paiDAO,bussineesContract,p1,"DIRECTOR",0);
//         tempBool = p1.callFunc4(bussineesContract);
//         assertTrue(tempBool);//9
//         assertEq(bussineesContract.states(),10);//10
//     }

//     function testVoteSpecial() public {
//         FakePaiDao paiDAO;
//         uint96 ASSET_PIS;
//         bool tempBool;
//         FakePerson admin = new FakePerson();
//         FakePerson director1 = new FakePerson();
//         FakePerson director2 = new FakePerson();
//         FakePerson director3 = new FakePerson();
//         FakePerson PISholder1 = new FakePerson();
//         FakePerson PISholder2 = new FakePerson();
//         FakePerson PISholder3 = new FakePerson();

//         ///init
//         paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
//         assertEq(paiDAO.tempAdmin(),admin);//0
//         tempBool = admin.callInit(paiDAO);
//         assertTrue(tempBool);//1
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder1);
//         assertTrue(tempBool);//2
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder2);
//         assertTrue(tempBool);//3
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder3);
//         assertTrue(tempBool);//4
//         (,ASSET_PIS) = paiDAO.Token(0);
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director1,0);
//         assertTrue(tempBool);//5
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director2,0);
//         assertTrue(tempBool);//6
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director3,0);
//         assertTrue(tempBool);//7
//         PISVoteManager voteManager = new PISVoteManager(paiDAO);
//         tempBool = PISholder1.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//8
//         tempBool = PISholder2.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//9
//         tempBool = PISholder3.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//10
        

//         // test voteSpecial
//         TimefliesVoteSP vote1 = new TimefliesVoteSP(paiDAO);
//         TestPaiDAO BC = new TestPaiDAO(paiDAO);
//         assertEq(BC.states(),0);//11
//         tempBool = PISholder1.callStartVoteTo(voteManager,vote1,"TEST",10,BC,hex"42eca434",hex"",100000000);
//         assertTrue(!tempBool);//12
//         tempBool = admin.callTempConfig(paiDAO,"VOTEMANAGER",voteManager,0);
//         tempBool = PISholder1.callStartVoteTo(voteManager,vote1,"TEST",10,BC,hex"42eca434",hex"",100000000);
//         assertTrue(tempBool);//13
//         assertEq(uint(vote1.getVoteStatus(1)),1);//14
//         tempBool = PISholder2.callVoteTo(voteManager,vote1,1,true,100000000);
//         assertTrue(tempBool);//15
//         assertEq(uint(vote1.getVoteStatus(1)),2);//16
//         tempBool = vote1.call(abi.encodeWithSelector(vote1.invokeVoteResult.selector,1));
//         assertTrue(!tempBool);//17
//         tempBool = admin.callTempConfig(paiDAO,"VOTE",vote1,0);
//         assertTrue(tempBool);//18
//         tempBool = vote1.call(abi.encodeWithSelector(vote1.invokeVoteResult.selector,1));
//         assertTrue(tempBool);//19
//         assertEq(BC.states(),2);//20
//     }

//     function testVoteStandard() public {
//         FakePaiDao paiDAO;
//         uint96 ASSET_PIS;
//         bool tempBool;
//         FakePerson admin = new FakePerson();
//         FakePerson director1 = new FakePerson();
//         FakePerson director2 = new FakePerson();
//         FakePerson director3 = new FakePerson();
//         FakePerson PISholder1 = new FakePerson();
//         FakePerson PISholder2 = new FakePerson();
//         FakePerson PISholder3 = new FakePerson();

//         ///init
//         paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
//         assertEq(paiDAO.tempAdmin(),admin);//0
//         tempBool = admin.callInit(paiDAO);
//         assertTrue(tempBool);//1
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder1);
//         assertTrue(tempBool);//2
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder2);
//         assertTrue(tempBool);//3
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder3);
//         assertTrue(tempBool);//4
//         (,ASSET_PIS) = paiDAO.Token(0);
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director1,0);
//         assertTrue(tempBool);//5
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director2,0);
//         assertTrue(tempBool);//6
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director3,0);
//         assertTrue(tempBool);//7
//         PISVoteManager voteManager = new PISVoteManager(paiDAO);
//         tempBool = PISholder1.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//8
//         tempBool = PISholder2.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//9
//         tempBool = PISholder3.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//10

//         // test voteStandard
//         TimefliesVoteST vote = new TimefliesVoteST(paiDAO);
//         TestPaiDAO BC = new TestPaiDAO(paiDAO);
//         assertEq(BC.states(),0);//11
//         tempBool = PISholder1.callStartVoteToStandard(voteManager,vote,"TEST",10,BC,1,50000000);
//         assertTrue(!tempBool);//12
//         tempBool = admin.callTempConfig(paiDAO,"VOTEMANAGER",voteManager,0);
//         tempBool = PISholder1.callStartVoteToStandard(voteManager,vote,"TEST",10,BC,1,50000000);
//         assertTrue(tempBool);//13
//         assertEq(uint(vote.getVoteStatus(1)),1);//14
//         tempBool = PISholder2.callVoteTo(voteManager,vote,1,true,40000000);
//         assertTrue(tempBool);//15
//         assertEq(uint(vote.getVoteStatus(1)),2);//16
//         tempBool = vote.call(abi.encodeWithSelector(vote.invokeVoteResult.selector,1));
//         assertTrue(!tempBool);//17
//         tempBool = admin.callTempConfig(paiDAO,"VOTE",vote,0);
//         assertTrue(tempBool);//18
//         tempBool = vote.call(abi.encodeWithSelector(vote.invokeVoteResult.selector,1));
//         assertTrue(tempBool);//19
//         assertEq(BC.states(),3);//20
//     }

//     function testDirectorVote() public {
//         FakePaiDao paiDAO;
//         uint96 ASSET_PIS;
//         bool tempBool;
//         FakePerson admin = new FakePerson();
//         FakePerson director1 = new FakePerson();
//         FakePerson director2 = new FakePerson();
//         FakePerson director3 = new FakePerson();
//         FakePerson PISholder1 = new FakePerson();
//         FakePerson PISholder2 = new FakePerson();
//         FakePerson PISholder3 = new FakePerson();

//         ///init
//         paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
//         assertEq(paiDAO.tempAdmin(),admin);//0
//         tempBool = admin.callInit(paiDAO);
//         assertTrue(tempBool);//1
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder1);
//         assertTrue(tempBool);//2
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder2);
//         assertTrue(tempBool);//3
//         tempBool = admin.callTempMintPIS(paiDAO,100000000,PISholder3);
//         assertTrue(tempBool);//4
//         (,ASSET_PIS) = paiDAO.Token(0);
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director1,0);
//         assertTrue(tempBool);//5
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director2,0);
//         assertTrue(tempBool);//6
//         tempBool = admin.callTempConfig(paiDAO,"DIRECTOR",director3,0);
//         assertTrue(tempBool);//7
//         PISVoteManager voteManager = new PISVoteManager(paiDAO);
//         tempBool = PISholder1.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//8
//         tempBool = PISholder2.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//9
//         tempBool = PISholder3.callDeposit(voteManager,100000000,ASSET_PIS);
//         assertTrue(tempBool);//10

//         // test directorVote
//         TimefliesVoteDir vote = new TimefliesVoteDir(paiDAO);
//         TestPaiDAO BC = new TestPaiDAO(paiDAO);
//         assertEq(BC.states(),0);//11
//         tempBool = PISholder1.callStartVote(vote,"TEST",10,BC,1);
//         assertTrue(!tempBool);//12
//         tempBool = director1.callStartVote(vote,"TEST",10,BC,1);
//         assertTrue(tempBool);//13
//         assertEq(uint(vote.getVoteStatus(1)),1);//14
//         tempBool = director1.callVote(vote,1,true);
//         assertTrue(!tempBool);//15
//         tempBool = director2.callVote(vote,1,true);
//         assertTrue(tempBool);//16
//         assertEq(uint(vote.getVoteStatus(1)),1);//17
//         tempBool = director3.callVote(vote,1,true);
//         assertTrue(tempBool);//18
//         assertEq(uint(vote.getVoteStatus(1)),2);//19
//         tempBool = vote.call(abi.encodeWithSelector(vote.invokeVoteResult.selector,1));
//         assertTrue(!tempBool);//20
//         tempBool = admin.callTempConfig(paiDAO,"VOTE",vote,0);
//         assertTrue(tempBool);//21
//         tempBool = vote.call(abi.encodeWithSelector(vote.invokeVoteResult.selector,1));
//         assertTrue(tempBool);//22
//         assertEq(BC.states(),2);//23
//     }
// }