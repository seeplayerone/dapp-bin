pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "github.com/seeplayerone/dapp-bin/pai-experimental/testcase/testPrepareNew.sol";

contract TestBase is Template, DSTest, DSMath {
    event printString(string);
    event printDoubleString(string,string);
    event printAddr(string,address);
    event printNumber(string,uint);
    event printAddrs(string,address[]);
    //others
    FakeBTCIssuer internal btcIssuer;
    FakeBTCIssuer internal ethIssuer;

    //MAIN
    FakePaiDao internal paiDAO;
    FakePAIIssuer internal paiIssuer;
    TimefliesElection internal election;
    TimefliesVoteSP internal VSP;
    TimefliesVoteST internal VST;
    TimefliesVoteDir internal DV;
    TimefliesOracle internal pisOracle;
    Setting internal setting;
    Finance internal finance;
    Liquidator internal PISseller;

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
    FakePerson internal director1;
    FakePerson internal director2;
    FakePerson internal director3;
    FakePerson internal airDropRobot;
    FakePerson internal CFO;
    FakePerson internal oracleManager;

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
        director1 = new FakePerson();
        director2 = new FakePerson();
        director3 = new FakePerson();
        airDropRobot = new FakePerson();
        CFO = new FakePerson();
        oracleManager = new FakePerson();

        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callChangeTopAdmin(paiDAO,"PISVOTE");
        admin.callChangeSuperior(paiDAO,"PISVOTE","PISVOTE");
        admin.callRemoveMember(paiDAO,admin,"ADMIN");

        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        
        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();
        election = new TimefliesElection(paiDAO);
        admin.callAddMember(paiDAO,election,"PISVOTE");
        admin.callCreateNewRole(paiDAO,"DIRECTOR","PISVOTE",3);
        admin.callAddMember(paiDAO,director1,"DIRECTOR");
        admin.callAddMember(paiDAO,director2,"DIRECTOR");
        admin.callAddMember(paiDAO,director3,"DIRECTOR");
        admin.callCreateNewRole(paiDAO,"EconomicSupervisor","PISVOTE",1);
        admin.callCreateNewRole(paiDAO,"TechnicalSupervisor","PISVOTE",1);
        admin.callCreateNewRole(paiDAO,"FinanceSupervisor","PISVOTE",1);
        admin.callCreateNewElectionType(election,"DIRECTOR",20);
        admin.callCreateNewElectionType(election,"EconomicSupervisor",1);
        admin.callCreateNewElectionType(election,"TechnicalSupervisor",1);
        admin.callCreateNewElectionType(election,"FinanceSupervisor",1);
        VSP = new TimefliesVoteSP(paiDAO);
        admin.callAddMember(paiDAO,VSP,"PISVOTE");
        VST = new TimefliesVoteST(paiDAO);
        admin.callAddMember(paiDAO,VST,"PISVOTE");
        DV = new TimefliesVoteDir(paiDAO);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","PISVOTE",0);
        admin.callAddMember(paiDAO,DV,"DIRECTORVOTE");
        pisOracle = new TimefliesOracle("PISOracle", paiDAO, RAY * 100, ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"PISOracle","PISVOTE",3);
        admin.callAddMember(paiDAO,oracle1,"PISOracle");
        admin.callAddMember(paiDAO,oracle2,"PISOracle");
        admin.callAddMember(paiDAO,oracle3,"PISOracle");
        admin.callCreateNewRole(paiDAO,"ORACLEMANAGER","DIRECTORVOTE",0);
        admin.callAddMember(paiDAO,oracleManager,"ORACLEMANAGER");
        setting = new Setting(paiDAO);
        finance = new Finance(paiDAO,paiIssuer,setting,pisOracle);
        admin.callCreateNewRole(paiDAO,"AirDropAddr","PISVOTE",0);
        admin.callCreateNewRole(paiDAO,"CFO","DIRECTORVOTE",0);
        admin.callAddMember(paiDAO,airDropRobot,"AirDropAddr");
        admin.callAddMember(paiDAO,CFO,"CFO");
        admin.callCreateNewRole(paiDAO,"FinanceContract","PISVOTE",0);
        admin.callAddMember(paiDAO,finance,"FinanceContract");
        admin.callCreateNewRole(paiDAO,"LiqudatorContract","PISVOTE",0);
        admin.callCreateNewRole(paiDAO,"TDCContract","PISVOTE",0);
        PISseller = new Liquidator(paiDAO,pisOracle, paiIssuer,"ADMIN",finance,setting);
        admin.callSetPISseller(finance,PISseller);
        btcOracle = new TimefliesOracle("BTCOracle", paiDAO, RAY * 70000, ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"BTCOracle","PISVOTE",3);
        admin.callAddMember(paiDAO,oracle1,"BTCOracle");
        admin.callAddMember(paiDAO,oracle2,"BTCOracle");
        admin.callAddMember(paiDAO,oracle3,"BTCOracle");
        btcLiquidator = new Liquidator(paiDAO,btcOracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callAddMember(paiDAO,btcLiquidator,"LiqudatorContract");
        btcCDP = new TimefliesCDP(paiDAO,paiIssuer,btcOracle,btcLiquidator,setting,finance,100000000000);
        admin.callCreateNewRole(paiDAO,"PAIMINTER","PISVOTE",0);
        admin.callAddMember(paiDAO,btcCDP,"PAIMINTER");
        admin.callCreateNewRole(paiDAO,"BTCCDP","PISVOTE",0);
        admin.callAddMember(paiDAO,btcCDP,"BTCCDP");
        
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
        admin.callAddMember(paiDAO,ethLiquidator,"LiqudatorContract");
        ethCDP = new TimefliesCDP(paiDAO,paiIssuer,ethOracle,ethLiquidator,setting,finance,30000000000);
        admin.callAddMember(paiDAO,ethCDP,"PAIMINTER");
        admin.callCreateNewRole(paiDAO,"ETHCDP","PISVOTE",0);
        admin.callAddMember(paiDAO,ethCDP,"ETHCDP");
        admin.callUpdateRatioLimit(setting, ASSET_ETH, RAY * 3 / 10);
        ethSettlement = new Settlement(paiDAO,ethOracle,ethCDP,ethLiquidator);
        admin.callAddMember(paiDAO,ethSettlement,"SettlementContract");

        tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
        admin.callSetTDC(finance, tdc);
        admin.callAddMember(paiDAO,tdc,"TDCContract");

        admin.callMint(paiDAO,3000000000000,this);
        //admin.callRemoveMember(paiDAO,admin,"DIRECTORVOTE");
        //admin.callRemoveMember(paiDAO,admin,"PISVOTE");
    }
}
contract Print is TestBase {
    function print() public {
        setup();
        admin.callRemoveMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callRemoveMember(paiDAO,admin,"PISVOTE");
        uint groupNumber = paiDAO.indexOfACL();
        for (uint i = 1; i <= groupNumber; i++) {
            emit printString("===================================================");
            emit printDoubleString("Role:",string(paiDAO.roles(i)));
            emit printDoubleString("Superior:",string(paiDAO.getSuperior(paiDAO.roles(i))));
            emit printNumber("memberLimit:",uint(paiDAO.getMemberLimit(paiDAO.roles(i))));
            emit printAddrs("members:",paiDAO.getMembers(paiDAO.roles(i)));
        }
        emit printString("===================================================");
        emit printAddr("paiDAO",paiDAO);
        emit printAddr("paiIssuer",paiIssuer);
        emit printAddr("pisOracle",pisOracle);
        emit printAddr("election",election);
        emit printAddr("VSP",VSP);
        emit printAddr("VST",VST);
        emit printAddr("DV",DV);
        emit printAddr("setting",setting);
        emit printAddr("finance",finance);
        emit printAddr("PISseller",PISseller);
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
        emit printAddr("director1",director1);
        emit printAddr("director2",director2);
        emit printAddr("director3",director3);
        emit printAddr("airDropRobot",airDropRobot);
        emit printAddr("CFO",CFO);
        emit printAddr("oracleManager",oracleManager);
    }
}

contract TestElection is TestBase {
    string DIRECTOR = "DIRECTOR";
    function testDirectorElection() public {
        setup();
        FakePerson PISHolder1 = new FakePerson();
        FakePerson PISHolder2 = new FakePerson();
        FakePerson PISHolder3 = new FakePerson();
        FakePerson p1 = new FakePerson();
        PISHolder1.transfer(1000000000000,ASSET_PIS);
        PISHolder2.transfer(1000000000000,ASSET_PIS);
        PISHolder3.transfer(1000000000000,ASSET_PIS);

        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),director1));
        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),director2));
        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),director3));

        bytes4 methodId = bytes4(keccak256("startElectionByDirector(bytes)"));
        bytes memory param = abi.encode("DIRECTOR");
        bool tempBool = director1.execute(election,methodId,param);
        assertTrue(tempBool);

        methodId = bytes4(keccak256("nominateCandidateByPIS(uint256,address)"));
        param = abi.encode(1,address(PISHolder1));
        tempBool = PISHolder1.execute(election,methodId,param,1000000000000,ASSET_PIS);
        assertTrue(tempBool);
        assertEq(flow.balance(PISHolder1,ASSET_PIS),1000000000000);
        methodId = bytes4(keccak256("quit(uint256)"));
        param = abi.encode(1);
        tempBool = director1.execute(election,methodId,param);
        assertTrue(tempBool);

        address[] list;
        list.push(PISHolder2);
        list.push(PISHolder3);
        list.push(p1);
        methodId = bytes4(keccak256("nominateByDirectors(uint256,address[])"));
        param = abi.encode(1,list);

        tempBool = admin.execute(election,methodId,param);
        assertTrue(!tempBool);

        election.fly(7 days);
        tempBool = admin.execute(election,methodId,param);
        assertTrue(tempBool);

        methodId = bytes4(keccak256("voteForCandidate(uint256,address)"));
        param = abi.encode(1,address(PISHolder1));
        tempBool = PISHolder1.execute(election,methodId,param,100,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,address(PISHolder2));
        tempBool = PISHolder1.execute(election,methodId,param,200,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,address(PISHolder3));
        tempBool = PISHolder1.execute(election,methodId,param,300,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,address(p1));
        tempBool = PISHolder1.execute(election,methodId,param,400,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,address(director1));
        tempBool = PISHolder1.execute(election,methodId,param,500,ASSET_PIS);
        assertTrue(!tempBool);
        param = abi.encode(1,address(director2));
        tempBool = PISHolder1.execute(election,methodId,param,500,ASSET_PIS);
        assertTrue(tempBool);
        election.fly(7 days);
        election.executeResult(1);
        assertTrue(!paiDAO.addressExist(bytes(DIRECTOR),director1));
        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),director2));
        assertTrue(!paiDAO.addressExist(bytes(DIRECTOR),director3));
        assertTrue(!paiDAO.addressExist(bytes(DIRECTOR),PISHolder1));
        assertTrue(!paiDAO.addressExist(bytes(DIRECTOR),PISHolder2));
        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),PISHolder3));
        assertTrue(paiDAO.addressExist(bytes(DIRECTOR),p1));
    }
}

contract TestVoteSP is TestBase {
    function testMintPIS() public {
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson PISHolder1 = new FakePerson();
        PISHolder1.transfer(1000000000000,ASSET_PIS);
        assertEq(flow.balance(p1,ASSET_PIS),0);

        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        PISVoteSpecial.ProposalItem[] memory items = new PISVoteSpecial.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(paiDAO);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        VSP.startProposal.value(1000000000000,ASSET_PIS)(ahash,0,items);

        methodId = bytes4(keccak256("pisVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = PISHolder1.execute(VSP,methodId,param,1000000000000,ASSET_PIS);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("invokeProposal(uint256)"));
        param = abi.encode(1);
        tempBool = PISHolder1.execute(VSP,methodId,param);
        assertTrue(!tempBool);
        VSP.fly(10 days + 5);
        tempBool = PISHolder1.execute(VSP,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PIS),600);
        tempBool = PISHolder1.execute(VSP,methodId,param);
        assertTrue(!tempBool);
    }
}

contract TestVoteST is TestBase {
    function testMintPIS() public {
        setup();
        FakePerson PISHolder1 = new FakePerson();
        FakePerson p1 = new FakePerson();
        PISHolder1.transfer(1000000000000,ASSET_PIS);
        assertEq(flow.balance(p1,ASSET_PIS),0);

        bytes32 ahash = keccak256("mintToP1");
        PISVoteStandard.StructForStartVote[] memory items = new PISVoteStandard.StructForStartVote[](3);
        items[0].target = address(paiDAO);
        items[0].funcId = 0;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(paiDAO);
        items[1].funcId = 0;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].funcId = 0;
        items[2].param = abi.encode(300,address(p1));
        VST.startProposal.value(1000000000000,ASSET_PIS)(ahash,0,0,items);


        bytes4 methodId = bytes4(keccak256("pisVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = PISHolder1.execute(VST,methodId,param,1000000000000,ASSET_PIS);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("invokeProposal(uint256)"));
        param = abi.encode(1);
        tempBool = PISHolder1.execute(VST,methodId,param);
        assertTrue(!tempBool);
        VST.fly(5 days + 5);
        tempBool = PISHolder1.execute(VST,methodId,param);
        assertTrue(tempBool);//5
        assertEq(flow.balance(p1,ASSET_PIS),600);//6
        tempBool = PISHolder1.execute(VST,methodId,param);
        assertTrue(!tempBool);
    }
}

contract TestVoteDir is TestBase {
    function VoteDirSetUp() public {
        setup();
        bytes4 func = bytes4(keccak256("changeState(uint8,bool)"));
        assertTrue(admin.callAddNewVoteParam(DV, 3, RAY / 5, func, 5 days / 5, 5 days / 5));//0
    }

    function testIncreaseOperationCashLimit() public {
        VoteDirSetUp();
        admin.callAddMember(paiDAO,DV,"PISVOTE");
        FakePerson PISHolder1 = new FakePerson();
        PISHolder1.transfer(1000000000000,ASSET_PIS);
        assertTrue(btcCDP.enable(0));
        assertTrue(btcCDP.enable(1));
        assertTrue(btcCDP.enable(2));

        bytes32 ahash = keccak256("changeTerm");
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(uint8(0),false);
        params[1] = abi.encode(uint8(1),false);
        params[2] = abi.encode(uint8(2),false);
        bool tempBool = PISHolder1.callStartProposal(DV,ahash,1,0,btcCDP,params);
        assertTrue(!tempBool);
        tempBool = director1.callStartProposal(DV,ahash,1,0,btcCDP,params);
        assertTrue(tempBool);

        bytes4 methodId = bytes4(keccak256("directorVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        tempBool = PISHolder1.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director1.execute(DV,methodId,param);
        assertTrue(tempBool);
        tempBool = director1.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director2.execute(DV,methodId,param);
        assertTrue(tempBool);
        tempBool = director1.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director2.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director3.execute(DV,methodId,param);
        assertTrue(tempBool);
        tempBool = director1.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director2.execute(DV,methodId,param);
        assertTrue(!tempBool);
        tempBool = director3.execute(DV,methodId,param);
        assertTrue(!tempBool);


        DV.advancePISVote(1);

        methodId = bytes4(keccak256("pisVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = PISHolder1.execute(DV,methodId,param,1000000000000,ASSET_PIS);
        assertTrue(tempBool);//8
        DV.fly(5 days + 5);
        methodId = bytes4(keccak256("invokeProposal(uint256)"));
        param = abi.encode(1);
        tempBool = PISHolder1.execute(DV,methodId,param);
        assertTrue(tempBool);//9
        assertTrue(!btcCDP.enable(0));
        assertTrue(!btcCDP.enable(1));
        assertTrue(!btcCDP.enable(2));
    }
}