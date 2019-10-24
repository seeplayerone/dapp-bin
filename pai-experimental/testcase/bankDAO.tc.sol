pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "./testPrepareNew.sol";

contract TestBase is Template, DSTest, DSMath {
    event printString(string);
    event printDoubleString(string,string);
    event printAddr(string,address);
    event printNumber(string,uint);
    event printAddrs(string,address[]);

    //contract
    FakePaiDao internal paiDAO;
    ProposalData internal proposal;
    TimefliesElection internal bankElection;
    TimefliesDIRVote internal CEOsuperior;
    BankAssistant internal assistant;
    TimefliesPISVote internal impeachVote;
    TimefliesDIRVote internal dirVote1;
    TimefliesDIRVote internal dirVote2;
    TimefliesBankBusiness internal business;
    FakeBankIssuer internal bankIssuer;
    BankFinance internal bankFinance;



    //FakePerson
    FakePerson internal founder;
    FakePerson internal secretary;

    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PIS;

    function() public payable {}

    function setup() public {
        //contract deployment
        paiDAO = new FakePaiDao("PAIDAO");
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        proposal = new ProposalData();
        bankElection = new TimefliesElection(paiDAO,"Director@Bank","DirectorBackUp@Bank");
        CEOsuperior = new TimefliesDIRVote(paiDAO, proposal, 0x0, RAY / 2, 3 days / 5, "Director@Bank","ADMIN");
        assistant = new BankAssistant(paiDAO);
        impeachVote = new TimefliesPISVote(paiDAO,proposal,RAY / 2,RAY * 2,7 days /5,"Director@Bank");
        dirVote1 = new TimefliesDIRVote(paiDAO, proposal, 0x0, RAY / 2, 3 days / 5, "Director@Bank","CEO@Bank");
        dirVote2 = new TimefliesDIRVote(paiDAO, proposal, 0x0, RAY, 3 days / 5, "Director@Bank","CEO@Bank");
        bankIssuer = new FakeBankIssuer("bankIssuer",paiDAO);
        bankIssuer.init();
        bankFinance = new BankFinance(paiDAO);
        business = new TimefliesBankBusiness(paiDAO, bankIssuer, bankFinance, 0);


        //fakeperson
        founder = new FakePerson();
        secretary = new FakePerson();

        //governance setting
        //remove admin
        paiDAO.createNewRole("PISVOTE","ADMIN",0,false);
        paiDAO.addMember(this,"PISVOTE");
        paiDAO.changeTopAdmin("PISVOTE");
        paiDAO.changeSuperior("PISVOTE","PISVOTE");
        paiDAO.removeMember(this,"ADMIN");
        //start setting
        paiDAO.createNewRole("DirectorElection@Bank","PISVOTE",0,false);
        paiDAO.addMember(bankElection,"DirectorElection@Bank");
        paiDAO.addMember(this,"DirectorElection@Bank");
        paiDAO.addMember(assistant,"DirectorElection@Bank");
        paiDAO.createNewRole("Director@Bank","DirectorElection@Bank",3,true);
        paiDAO.createNewRole("DirectorBackUp@Bank","DirectorElection@Bank",0,false);
        paiDAO.createNewRole("Founder","PISVOTE",0,false);
        paiDAO.addMember(founder,"Founder");
        paiDAO.changeSuperior("Founder","Founder");
        paiDAO.createNewRole("Secretary","PISVOTE",0,false);
        paiDAO.addMember(secretary,"Secretary");
        paiDAO.changeSuperior("Secretary","Founder");
        paiDAO.createNewRole("CEOsuperior@Bank","PISVOTE",0,false);
        paiDAO.addMember(CEOsuperior,"CEOsuperior@Bank");
        paiDAO.addMember(this,"CEOsuperior@Bank");
        paiDAO.createNewRole("CEO@Bank","CEOsuperior@Bank",1,true);
        paiDAO.createNewRole("ImpeachmentVote@Bank","PISVOTE",0,false);
        paiDAO.addMember(impeachVote,"ImpeachmentVote@Bank");
        paiDAO.createNewRole("50%DirVote@Bank","PISVOTE",0,false);
        paiDAO.addMember(dirVote1,"50%DirVote@Bank");
        paiDAO.addMember(this,"50%DirVote@Bank");
        paiDAO.createNewRole("Minter@Bank","50%DirVote@Bank",0,false);
        paiDAO.createNewRole("AuditorSuperior@Bank","PISVOTE",0,false);
        paiDAO.addMember(assistant,"AuditorSuperior@Bank");
        paiDAO.createNewRole("Auditor@Bank","AuditorSuperior@Bank",0,false);
        paiDAO.createNewRole("WalletManager@Bank","Director@Bank",0,false);
        paiDAO.createNewRole("BusinessContract@Bank","PISVOTE",0,false);
        paiDAO.addMember(business,"BusinessContract@Bank");
        paiDAO.createNewRole("100%DirVote@Bank","PISVOTE",0,false);
        paiDAO.addMember(dirVote2,"100%DirVote@Bank");

        //mint money, should not be include when real environment
        paiDAO.mint(300000000,this);
    }
}

contract Print is TestBase {
    function print() public {
        setup();
        paiDAO.removeMember(this,"DirectorElection@Bank");
        paiDAO.removeMember(this,"CEOsuperior@Bank");
        paiDAO.removeMember(this,"50%DirVote@Bank");
        paiDAO.removeMember(this,"PISVOTE");
        uint groupNumber = paiDAO.indexOfACL();
        for (uint i = 1; i <= groupNumber; i++) {
            emit printString("===================================================");
            emit printDoubleString("Role:",string(paiDAO.roles(i)));
            emit printDoubleString("Superior:",string(paiDAO.getSuperior(paiDAO.roles(i))));
            emit printNumber("memberLimit:",uint(paiDAO.getMemberLimit(paiDAO.roles(i))));
            emit printAddrs("members:",paiDAO.getMembers(paiDAO.roles(i)));
        }
        emit printString("===================================================");
        //contract
        emit printAddr("paiDAO",paiDAO);
        // emit printAddr("paiIssuer",paiIssuer);
        // emit printAddr("pisOracle",pisOracle);
        // emit printAddr("election",election);
        // emit printAddr("VSP",VSP);
        // emit printAddr("VST",VST);
        // emit printAddr("DV",DV);
        // emit printAddr("setting",setting);
        // emit printAddr("finance",finance);
        // emit printAddr("PISseller",PISseller);
        // emit printAddr("btcOracle",btcOracle);
        // emit printAddr("btcLiquidator",btcLiquidator);
        // emit printAddr("btcCDP",btcCDP);
        // emit printAddr("btcSettlement",btcSettlement);
        // emit printAddr("ethOracle",ethOracle);
        // emit printAddr("ethLiquidator",ethLiquidator);
        // emit printAddr("ethCDP",ethCDP);
        // emit printAddr("ethSettlement",ethSettlement);
        // emit printAddr("tdc",tdc);
        //person
        emit printAddr("Admin",this);
        // emit printAddr("oracle1",oracle1);
        // emit printAddr("oracle2",oracle2);
        // emit printAddr("oracle3",oracle3);
        // emit printAddr("director1",director1);
        // emit printAddr("director2",director2);
        // emit printAddr("director3",director3);
        // emit printAddr("airDropRobot",airDropRobot);
        // emit printAddr("CFO",CFO);
        // emit printAddr("oracleManager",oracleManager);
    }
}

contract TestElection is TestBase {
    string s1 = "Director@Bank";
    string s2 = "DirectorBackUp@Bank";
    function testNormalElection() public {
        //prepare
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        FakePerson p5 = new FakePerson();
        p1.transfer(100000000,ASSET_PIS);
        p2.transfer(100000000,ASSET_PIS);
        p3.transfer(100000000,ASSET_PIS);

        //start a election
        bytes4 methodId = bankElection.startElection.selector;
        address[] list;
        bytes memory param = abi.encode(2,list);
        bool tempBool = secretary.execute(bankElection,methodId,param);
        assertTrue(tempBool);
        assertEq(bankElection.currentIndex(),1);

        //nominate by pis
        methodId = bytes4(keccak256("nominateCandidatesByAsset(address[])"));
        list.push(p1);
        list.push(p2);
        param = abi.encode(list);
        tempBool = p1.execute(bankElection,methodId,param,0,ASSET_PIS);
        assertTrue(!tempBool);
        tempBool = p1.execute(bankElection,methodId,param,30000000,ASSET_PIS);
        assertTrue(tempBool);
        //nominate by founder
        list.length--;
        list.length--;
        list.push(p3);
        list.push(p4);
        list.push(p5);
        methodId = bytes4(keccak256("nominateCandidatesByFoundingTeam(address[])"));
        param = abi.encode(list);
        tempBool = founder.execute(bankElection,methodId,param);
        assertTrue(tempBool);

        //elect
        bankElection.fly(7 days);
        methodId = bytes4(keccak256("voteForCandidate(uint256,address)"));
        param = abi.encode(1,p1);
        tempBool = p1.execute(bankElection,methodId,param,1000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,p2);
        tempBool = p1.execute(bankElection,methodId,param,2000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,p3);
        tempBool = p1.execute(bankElection,methodId,param,3000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,p4);
        tempBool = p1.execute(bankElection,methodId,param,4000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(1,p5);
        tempBool = p1.execute(bankElection,methodId,param,5000,ASSET_PIS);
        assertTrue(tempBool);

        //execute the result
        bankElection.fly(7 days);
        methodId = bytes4(keccak256("processElectionResult()"));
        param = abi.encode();
        tempBool = secretary.execute(bankElection,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s1),p5));
        assertTrue(paiDAO.addressExist(bytes(s1),p4));
        assertTrue(paiDAO.addressExist(bytes(s1),p3));
        assertTrue(paiDAO.addressExist(bytes(s2),p2));
        assertTrue(paiDAO.addressExist(bytes(s2),p1));

        //quit and add
        methodId = bytes4(keccak256("quit(bytes)"));
        param = abi.encode(bytes(s1));
        tempBool = p5.execute(paiDAO,methodId,param);
        assertTrue(tempBool);
        param = abi.encode(bytes(s2));
        tempBool = p1.execute(paiDAO,methodId,param);
        assertTrue(!tempBool);
        bankElection.addDirector();
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(!paiDAO.addressExist(bytes(s2),p2));
        param = abi.encode(bytes(s1));
        tempBool = p4.execute(paiDAO,methodId,param);
        assertTrue(tempBool);
        tempBool = p3.execute(paiDAO,methodId,param);
        assertTrue(tempBool);
        bankElection.addDirector();
        assertTrue(paiDAO.addressExist(bytes(s1),p1));

        //supplement
        methodId = bankElection.startElectionSupplement.selector;
        list.length--;
        list.length--;
        list.length--;
        param = abi.encode(2,list);
        tempBool = secretary.execute(bankElection,methodId,param);
        assertTrue(tempBool);
        assertEq(bankElection.currentIndex(),2);
        list.push(p3);
        list.push(p4);
        list.push(p5);
        methodId = bytes4(keccak256("nominateCandidatesByFoundingTeam(address[])"));
        param = abi.encode(list);
        tempBool = founder.execute(bankElection,methodId,param);
        assertTrue(tempBool);
        bankElection.fly(7 days);
        methodId = bytes4(keccak256("voteForCandidate(uint256,address)"));
        param = abi.encode(2,p3);
        tempBool = p1.execute(bankElection,methodId,param,1000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(2,p4);
        tempBool = p1.execute(bankElection,methodId,param,2000,ASSET_PIS);
        assertTrue(tempBool);
        param = abi.encode(2,p5);
        tempBool = p1.execute(bankElection,methodId,param,3000,ASSET_PIS);
        assertTrue(tempBool);
        bankElection.fly(7 days);
        methodId = bytes4(keccak256("processElectionResult()"));
        param = abi.encode();
        tempBool = secretary.execute(bankElection,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(paiDAO.addressExist(bytes(s1),p5));
        assertTrue(paiDAO.addressExist(bytes(s2),p3));
        assertTrue(paiDAO.addressExist(bytes(s2),p4));

    }
}

contract TestCEORelated is TestBase {
    string s1 = "Director@Bank";
    string s2 = "CEO@Bank";
    function testVote() public {
        //prepare
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        address[] list;
        list.push(p1);
        list.push(p2);
        list.push(p3);
        paiDAO.resetMembers(list,bytes(s1));
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(paiDAO.addressExist(bytes(s1),p3));

        //proposal
        list.length--;
        list.length--;
        list.length--;
        list.push(p4);
        bytes32 ahash = keccak256("resetMembers");
        bytes4 methodId = bytes4(keccak256("resetMembers(address[],bytes)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(list,bytes(s2));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);

        //start vote
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        bytes memory param = abi.encode(1,0,0);
        bool tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);

        //vote
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s2),p4));
        tempBool = p2.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s2),p4));

        //quit
        methodId = bytes4(keccak256("quit(bytes)"));
        param = abi.encode(bytes(s2));
        tempBool = p4.execute(paiDAO,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s2),p4));

        //proposal add
        ahash = keccak256("addMember");
        methodId = bytes4(keccak256("addMember(address,bytes)"));
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(p4,bytes(s2));
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,2);
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        param = abi.encode(2,0,0);
        tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(2,0);
        tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s2),p4));
        tempBool = p2.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s2),p4));

        ///proposal remove
        ahash = keccak256("removeMember");
        methodId = bytes4(keccak256("removeMember(address,bytes)"));
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(p4,bytes(s2));
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,3);
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        param = abi.encode(3,0,0);
        tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(3,0);
        tempBool = p1.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s2),p4));
        tempBool = p2.execute(CEOsuperior,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s2),p4));
    }
}

contract TestImpeach is TestBase {
    string s1 = "Director@Bank";
    function testImpeachment() public {
        //prepare
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        address[] list;
        list.push(p1);
        list.push(p2);
        list.push(p3);
        paiDAO.resetMembers(list,bytes(s1));
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(paiDAO.addressExist(bytes(s1),p3));
        p1.transfer(100000000,ASSET_PIS);

        //proposal
        bytes32 ahash = keccak256("impeachDirector");
        bytes4 methodId = bytes4(keccak256("impeachDirector(address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(assistant);
        items[0].func = methodId;
        items[0].param = abi.encode(address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);

        //start vote
        methodId = bytes4(keccak256("startVoteByAuthroity(uint256,uint256)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = p1.execute(impeachVote,methodId,param);
        assertTrue(tempBool);

        //vote
        methodId = bytes4(keccak256("pisVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = p1.execute(impeachVote,methodId,param,100000000,ASSET_PIS);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        impeachVote.fly(7 days + 5);
        assertTrue(paiDAO.addressExist(bytes(s1),p1));

        //excute
        impeachVote.invokeVote(1);
        assertTrue(!paiDAO.addressExist(bytes(s1),p1));

    }
}

contract TestDirVote is TestBase {
    string s1 = "Director@Bank";
    string s2 = "CEO@Bank";
    string s3 = "Minter@Bank";
    function testAddMinter() public {
        //prepare
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        address[] list;
        list.push(p1);
        list.push(p2);
        list.push(p3);
        paiDAO.resetMembers(list,bytes(s1));
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(paiDAO.addressExist(bytes(s1),p3));
        paiDAO.addMember(p4,bytes(s2));
        assertTrue(paiDAO.addressExist(bytes(s2),p4));

        //proposal add
        bytes32 ahash = keccak256("addMember");
        bytes4 methodId = bytes4(keccak256("addMember(address,bytes)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(p1,bytes(s3));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        bytes memory param = abi.encode(1,0,0);
        bool tempBool = p1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = p1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s3),p1));
        tempBool = p2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s3),p1));

        //remove
        ahash = keccak256("removeMember");
        methodId = bytes4(keccak256("removeMember(address,bytes)"));
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(p1,bytes(s3));
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,2);
        methodId = bytes4(keccak256("startVoteByOthers(uint256,uint256,uint8)"));
        param = abi.encode(2,0,0);
        tempBool = p4.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(2,0);
        tempBool = p1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s3),p1));
        tempBool = p2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s3),p1));
    }
}

contract TestAuditor is TestBase {
    string s1 = "Director@Bank";
    string s2 = "CEO@Bank";
    string s3 = "Auditor@Bank";
    function testAll() public {
        //prepare
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        address[] list;
        list.push(p1);
        list.push(p2);
        list.push(p3);
        paiDAO.resetMembers(list,bytes(s1));
        assertTrue(paiDAO.addressExist(bytes(s1),p1));
        assertTrue(paiDAO.addressExist(bytes(s1),p2));
        assertTrue(paiDAO.addressExist(bytes(s1),p3));
        paiDAO.addMember(p4,bytes(s2));
        assertTrue(paiDAO.addressExist(bytes(s2),p4));

        //ceo
        assertTrue(!paiDAO.addressExist(bytes(s3),p1));
        bytes4 methodId = bytes4(keccak256("addAuditorByCEO(address)"));
        bytes memory param = abi.encode(p1);
        bool tempBool = p4.execute(assistant,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s3),p1));
        methodId = bytes4(keccak256("removeAuditorByCEO(address)"));
        param = abi.encode(p1);
        tempBool = p4.execute(assistant,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s3),p1));
        list.length--;
        list.length--;
        list.length--;
        list.push(p2);
        list.push(p3);
        assertTrue(!paiDAO.addressExist(bytes(s3),p2));
        assertTrue(!paiDAO.addressExist(bytes(s3),p3));
        methodId = bytes4(keccak256("resetAuditorsByCEO(address[])"));
        param = abi.encode(list);
        tempBool = p4.execute(assistant,methodId,param);
        assertTrue(paiDAO.addressExist(bytes(s3),p2));
        assertTrue(paiDAO.addressExist(bytes(s3),p3));

        //director
        methodId = bytes4(keccak256("removeAuditorByDirector(address)"));
        param = abi.encode(p2);
        tempBool = p1.execute(assistant,methodId,param);
        assertTrue(tempBool);
        assertTrue(!paiDAO.addressExist(bytes(s3),p2));
        methodId = bytes4(keccak256("addAuditorByDirector(address)"));
        param = abi.encode(p1);
        tempBool = p1.execute(assistant,methodId,param);
        assertTrue(tempBool);
        assertTrue(paiDAO.addressExist(bytes(s3),p1));
        list.length--;
        list.length--;
        list.push(p2);
        list.push(p4);
        assertTrue(paiDAO.addressExist(bytes(s3),p1));
        assertTrue(paiDAO.addressExist(bytes(s3),p3));
        assertTrue(!paiDAO.addressExist(bytes(s3),p2));
        assertTrue(!paiDAO.addressExist(bytes(s3),p4));
        methodId = bytes4(keccak256("resetAuditorsByDirector(address[])"));
        param = abi.encode(list);
        tempBool = p1.execute(assistant,methodId,param);
        assertTrue(!paiDAO.addressExist(bytes(s3),p1));
        assertTrue(!paiDAO.addressExist(bytes(s3),p3));
        assertTrue(paiDAO.addressExist(bytes(s3),p2));
        assertTrue(paiDAO.addressExist(bytes(s3),p4));
    }
}

contract TestFunction is TestBase {
    string s1 = "Director@Bank";
    string s2 = "CEO@Bank";
    FakePerson director1;
    FakePerson director2;
    FakePerson director3;
    FakePerson ceo;
    uint96 ASSET_BTC;
    uint96 ASSET_ETH;
    function funcSetup() public {
        setup();
        director1 = new FakePerson();
        director2 = new FakePerson();
        director3 = new FakePerson();
        ceo = new FakePerson();
        address[] list;
        list.push(director1);
        list.push(director2);
        list.push(director3);
        paiDAO.resetMembers(list,bytes(s1));
        assertTrue(paiDAO.addressExist(bytes(s1),director1));
        assertTrue(paiDAO.addressExist(bytes(s1),director2));
        assertTrue(paiDAO.addressExist(bytes(s1),director3));
        paiDAO.addMember(ceo,bytes(s2));
        assertTrue(paiDAO.addressExist(bytes(s2),ceo));
    }

    function testNewAsset() public {
        funcSetup();
        //proposal
        bytes32 ahash = keccak256("createNewAsset");
        bytes4 methodId = bytes4(keccak256("createNewAsset(uint256,uint256,uint256,uint256,uint256,uint256,uint256,string,string,string)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(10000,5000,500,50,1500,RAY / 20,RAY / 20,"BTC","BTC","BitCoin");
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);

        //strat vote
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        bytes memory param = abi.encode(1,0,0);
        bool tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);

        //vote
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(!bankIssuer.exist(1));
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(bankIssuer.exist(1));
        ASSET_BTC = bankIssuer.AssetGlobalId(1);

        //by CEO
        methodId = business.createNewAsset.selector;
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(20000,200,2000,20,20000,RAY / 10,RAY / 10,"ETH","ETH","Ethereum");
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,2);

        //strat vote
        methodId = bytes4(keccak256("startVoteByOthers(uint256,uint256,uint8)"));
        param = abi.encode(2,0,0);
        tempBool = ceo.execute(dirVote1,methodId,param);
        assertTrue(tempBool);

        //vote
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(2,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(!bankIssuer.exist(2));
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertTrue(bankIssuer.exist(2));
        ASSET_ETH = bankIssuer.AssetGlobalId(2);
    }

    function testCashIn() public {
        testNewAsset();
        FakePerson minter1 = new FakePerson();
        FakePerson minter2 = new FakePerson();
        paiDAO.addMember(minter1,"Minter@Bank");
        paiDAO.addMember(minter2,"Minter@Bank");

        FakePerson p1 = new FakePerson();
        //normal
        bytes4 methodId = business.deposit.selector;
        bytes memory param = abi.encode("aa","aa",p1,1,6000);
        bool tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);
        param = abi.encode("aa","aa",p1,1,5000);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),4750);
        assertEq(flow.balance(bankFinance,ASSET_BTC),250);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),9500);
        assertEq(flow.balance(bankFinance,ASSET_BTC),500);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);
        business.fly(1 days);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),19000);
        assertEq(flow.balance(bankFinance,ASSET_BTC),1000);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);
        tempBool = minter2.execute(business,methodId,param);
        assertTrue(tempBool);
        tempBool = minter2.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),28500);
        assertEq(flow.balance(bankFinance,ASSET_BTC),1500);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);        
        assertEq(flow.balance(p1,ASSET_ETH),180);
        assertEq(flow.balance(bankFinance,ASSET_ETH),20);
        assertEq(bankIssuer.totalSupply(1),30000);
        assertEq(bankIssuer.totalSupply(2),200);
    }

    function testCashInVote() public {
        testNewAsset();
        FakePerson minter1 = new FakePerson();
        paiDAO.addMember(minter1,"Minter@Bank");
        FakePerson p1 = new FakePerson();

        //start vote
        bytes4 methodId = business.startCashOutVote.selector;
        bytes memory param = abi.encode(p1,1,6000);
        bool tempBool = p1.execute(business,methodId,param);
        assertTrue(!tempBool);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);

        //vote
        methodId = business.vote.selector;
        param = abi.encode(1);
        tempBool = p1.execute(business,methodId,param);
        assertTrue(!tempBool);
        tempBool = director1.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),0);
        tempBool = director1.execute(business,methodId,param);
        assertTrue(!tempBool);
        tempBool = director2.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),5700);

        //test overTime
        methodId = business.startCashOutVote.selector;
        param = abi.encode(p1,1,6000);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        methodId = business.vote.selector;
        param = abi.encode(2);
        tempBool = director1.execute(business,methodId,param);
        assertTrue(tempBool);
        business.fly(3 days + 5);
        tempBool = director2.execute(business,methodId,param);
        assertTrue(!tempBool);
        tempBool = director3.execute(business,methodId,param);
        assertTrue(!tempBool);
    }

    function testCashOut() public {
        testNewAsset();
        FakePerson minter1 = new FakePerson();
        paiDAO.addMember(minter1,"Minter@Bank");
        FakePerson p1 = new FakePerson();
        bytes4 methodId = business.deposit.selector;
        bytes memory param = abi.encode("aa","aa",p1,1,5000);
        bool tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),4750);
        assertEq(flow.balance(bankFinance,ASSET_BTC),250);
        assertEq(bankIssuer.totalSupply(1),5000);

        //success
        methodId = bytes4(keccak256("withdraw(string)"));
        param = abi.encode("aa");
        tempBool = p1.execute(business,methodId,param,500,ASSET_BTC);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),4250);
        assertEq(flow.balance(bankFinance,ASSET_BTC),275);
        assertEq(bankIssuer.totalSupply(1),4525);

        //fail
        tempBool = p1.execute(business,methodId,param,49,ASSET_BTC);
        assertTrue(!tempBool);
        tempBool = p1.execute(business,methodId,param,501,ASSET_BTC);
        assertTrue(!tempBool);
        tempBool = p1.execute(business,methodId,param,500,ASSET_BTC);
        assertTrue(tempBool);
        tempBool = p1.execute(business,methodId,param,500,ASSET_BTC);
        assertTrue(tempBool);
        tempBool = p1.execute(business,methodId,param,500,ASSET_BTC);
        assertTrue(!tempBool);
    }


    function testCloseBusiness() public {
        testNewAsset();
        FakePerson minter1 = new FakePerson();
        paiDAO.addMember(minter1,"Minter@Bank");
        FakePerson p1 = new FakePerson();
        bytes4 methodId = business.deposit.selector;
        bytes memory param = abi.encode("aa","aa",p1,1,500);
        bool tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);

        bytes32 ahash = keccak256("closeAll");
        methodId = bytes4(keccak256("switchAllBusiness(bool)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(true);
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,3);

        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        param = abi.encode(3,0,0);
        tempBool = director1.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(!business.disableAll());
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(1,0);
        tempBool = director1.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(!business.disableAll());
        tempBool = director2.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(!business.disableAll());
        tempBool = director3.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(business.disableAll());
        methodId = business.deposit.selector;
        param = abi.encode("aa","aa",p1,1,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);

        methodId = bytes4(keccak256("switchAllBusiness(bool)"));
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(false);
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,4);
        methodId = bytes4(keccak256("startVoteByOthers(uint256,uint256,uint8)"));
        param = abi.encode(4,0,0);
        tempBool = ceo.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(2,0);
        tempBool = director1.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(business.disableAll());
        tempBool = director2.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(business.disableAll());
        tempBool = director3.execute(dirVote2,methodId,param);
        assertTrue(tempBool);
        assertTrue(!business.disableAll());
        methodId = business.deposit.selector;
        param = abi.encode("aa","aa",p1,1,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
    }

    function testCloseOneCoin() public {
        testNewAsset();
        FakePerson minter1 = new FakePerson();
        paiDAO.addMember(minter1,"Minter@Bank");
        FakePerson p1 = new FakePerson();
        bytes4 methodId = business.deposit.selector;
        bytes memory param = abi.encode("aa","aa",p1,1,500);
        bool tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);

        bytes32 ahash = keccak256("closeOneCoin");
        methodId = bytes4(keccak256("switchAssetBusiness(uint32,bool)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(1,false);
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,3);

        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        param = abi.encode(3,0,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(3,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = business.deposit.selector;
        param = abi.encode("aa","aa",p1,1,500);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(!tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);

        methodId = bytes4(keccak256("switchAssetBusiness(uint32,bool)"));
        items[0].target = address(business);
        items[0].func = methodId;
        items[0].param = abi.encode(1,true);
        proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,4);
        methodId = bytes4(keccak256("startVoteByOthers(uint256,uint256,uint8)"));
        param = abi.encode(4,0,0);
        tempBool = ceo.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(4,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = business.deposit.selector;
        param = abi.encode("aa","aa",p1,1,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
        param = abi.encode("aa","aa",p1,2,200);
        tempBool = minter1.execute(business,methodId,param);
        assertTrue(tempBool);
    }

    function testFinanceCashOut() public {
        testNewAsset();
        FakePerson p1 = new FakePerson();
        bankFinance.transfer(1000000,ASSET_PIS);
        bytes32 ahash = keccak256("cashOut");
        bytes4 methodId = bytes4(keccak256("cashOut(uint96,uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](1);
        items[0].target = address(bankFinance);
        items[0].func = methodId;
        items[0].param = abi.encode(ASSET_PIS,100000,p1);
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,3);
        methodId = bytes4(keccak256("startVote(uint256,uint256,uint8)"));
        bytes memory param = abi.encode(3,0,0);
        bool tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(3,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PIS),100000);

        methodId = bytes4(keccak256("startVoteByOthers(uint256,uint256,uint8)"));
        param = abi.encode(3,0,0);
        tempBool = ceo.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        param = abi.encode(4,0);
        tempBool = director1.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        tempBool = director2.execute(dirVote1,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PIS),200000);
    }

    function testSetting() public {
        //10000,5000,500,50,1500,RAY / 20,RAY / 20
        testNewAsset();
        uint temp;
        (temp,,,,,,,,,,) = business.params(1);
        assertEq(temp,10000);
        business.setDailyCashInLimit(1,20000);
        (temp,,,,,,,,,,) = business.params(1);
        assertEq(temp,20000);

        (,temp,,,,,,,,,) = business.params(1);
        assertEq(temp,5000);
        business.setSingleCashInLimit(1,20000);
        (,temp,,,,,,,,,) = business.params(1);
        assertEq(temp,20000);
        
        (,,temp,,,,,,,,) = business.params(1);
        assertEq(temp,500);
        business.setSingleCashOutUpperLimit(1,20000);
        (,,temp,,,,,,,,) = business.params(1);
        assertEq(temp,20000);

        (,,,temp,,,,,,,) = business.params(1);
        assertEq(temp,50);
        business.setSingleCashOutLowerLimit(1,20000);
        (,,,temp,,,,,,,) = business.params(1);
        assertEq(temp,20000);

        (,,,,temp,,,,,,) = business.params(1);
        assertEq(temp,1500);
        business.setDailyCashOutLimit(1,20000);
        (,,,,temp,,,,,,) = business.params(1);
        assertEq(temp,20000);

        (,,,,,temp,,,,,) = business.params(1);
        assertEq(temp,RAY / 20);
        business.setCashInRate(1,20000);
        (,,,,,temp,,,,,) = business.params(1);
        assertEq(temp,20000);

        (,,,,,,temp,,,,) = business.params(1);
        assertEq(temp,RAY / 20);
        business.setCashOutRate(1,20000);
        (,,,,,,temp,,,,) = business.params(1);
        assertEq(temp,20000);
    }
}

