pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "./testPrepare.sol";

contract TestBase is Template, DSTest, DSMath {
    FakeBTCIssuer internal btcIssuer;
    FakePerson internal admin;
    FakePerson internal p1;
    FakePerson internal p2;
    FakePaiDaoNoGovernance internal paiDAO;
    TimefliesPISVote internal vote;
    ProposalData internal proposal;
    TimefliesDIRVote internal dirvote1;
    TimefliesDIRVote internal dirvote2;
    TimefliesDemonstration internal demonstration;
    string director = "director";


    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PIS;

    function() public payable {}

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDaoNoGovernance(admin.createPAIDAONoGovernance("PAIDAO"));
        paiDAO.init();
        ASSET_PIS= paiDAO.PISGlobalId();
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());
        proposal = new ProposalData();
        vote = new TimefliesPISVote(paiDAO,proposal,RAY * 2 / 3,RAY / 20, 10 days / 5,"test");
        demonstration = new TimefliesDemonstration(paiDAO, proposal, vote, RAY / 10, 1 days / 5, "test");
        dirvote1 = new TimefliesDIRVote(paiDAO, proposal, vote, RAY, 10 days / 5, "director","lala");
        dirvote2 = new TimefliesDIRVote(paiDAO, proposal, demonstration, RAY/2, 10 days / 5, "director","lala");
        admin.callCreateNewRole(paiDAO,"director","ADMIN",4,true);
        //assertEq(uint(paiDAO.getMemberLimit(bytes(director))),4);
        paiDAO.mint(100000000,this);
    }
}

contract FunctionTest is TestBase {
    function testPISvote() public {
        setup();
        FakePerson p1 = new FakePerson();
        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(btcIssuer);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        vote.startVote.value(100000000,ASSET_PIS)(1,0);
        vote.pisVote.value(100000000,ASSET_PIS)(1, PISVote.VoteAttitude.AGREE);
        vote.fly(10 days + 5);
        vote.invokeVote(1);
        assertEq(flow.balance(p1,ASSET_BTC),200);
        assertEq(flow.balance(p1,ASSET_PIS),400);
    }

    function testDIRvote() public {
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(btcIssuer);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        dirvote1.startVote(1,0,DIRVote.ExectionType.DIRECTLY);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = p1.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),0);
        assertEq(flow.balance(p1,ASSET_PIS),0);
        tempBool = p1.execute(dirvote1,methodId,param);
        assertTrue(!tempBool);
        tempBool = p2.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        tempBool = p3.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),0);
        assertEq(flow.balance(p1,ASSET_PIS),0);
        tempBool = p4.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_BTC),200);
        assertEq(flow.balance(p1,ASSET_PIS),400);
    }

    function testDIRvote2PISvote() public {
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(btcIssuer);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        dirvote1.startVote(1,0,DIRVote.ExectionType.TRIGGERNEWVOTE);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = p1.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        tempBool = p2.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        tempBool = p3.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        tempBool = p4.execute(dirvote1,methodId,param);
        assertTrue(tempBool);
        vote.pisVote.value(100000000,ASSET_PIS)(1, PISVote.VoteAttitude.AGREE);
        vote.fly(10 days + 5);
        vote.invokeVote(1);
        assertEq(flow.balance(p1,ASSET_BTC),200);
        assertEq(flow.balance(p1,ASSET_PIS),400);
    }

    function testDIRvote2Demonstration() public {
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(btcIssuer);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        dirvote2.startVote(1,0,DIRVote.ExectionType.TRIGGERNEWVOTE);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = p1.execute(dirvote2,methodId,param);
        assertTrue(tempBool);
        tempBool = p2.execute(dirvote2,methodId,param);
        assertTrue(tempBool);
        demonstration.fly(1 days + 5);
        demonstration.invokeVote(1);
        assertEq(flow.balance(p1,ASSET_BTC),200);
        assertEq(flow.balance(p1,ASSET_PIS),400);
    }

    function testDIRvote2Demonstration2PISvote() public {
        setup();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        bytes32 ahash = keccak256("mintToP1");
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        ProposalData.ProposalItem[] memory items = new ProposalData.ProposalItem[](3);
        items[0].target = address(paiDAO);
        items[0].func = methodId;
        items[0].param = abi.encode(100,address(p1));
        items[1].target = address(btcIssuer);
        items[1].func = methodId;
        items[1].param = abi.encode(200,address(p1));
        items[2].target = address(paiDAO);
        items[2].func = methodId;
        items[2].param = abi.encode(300,address(p1));
        uint proposalId = proposal.newProposal(ahash,items);
        assertEq(proposalId,1);
        dirvote2.startVote(1,0,DIRVote.ExectionType.TRIGGERNEWVOTE);
        methodId = bytes4(keccak256("dirVote(uint256,uint8)"));
        bytes memory param = abi.encode(1,0);
        bool tempBool = p1.execute(dirvote2,methodId,param);
        assertTrue(tempBool);
        tempBool = p2.execute(dirvote2,methodId,param);
        assertTrue(tempBool);
        demonstration.pisVote.value(100000000,ASSET_PIS)(1);
        vote.pisVote.value(100000000,ASSET_PIS)(1, PISVote.VoteAttitude.AGREE);
        vote.fly(10 days + 5);
        vote.invokeVote(1);
        assertEq(flow.balance(p1,ASSET_BTC),200);
        assertEq(flow.balance(p1,ASSET_PIS),400);
    }
}