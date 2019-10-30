pragma solidity 0.4.25;

import "./dao_asimov.sol";
import "./simple_vote.sol";
import "../utils/ds_test.sol";
import "../utils/execution.sol";

contract FakeDAO is Association{
    constructor(string organizationName, address[] _members)
        Association(organizationName, _members, "vote") 
        public 
        {
            templateName = "Fake-Template-Name-4-Test";

            assetVoteContractAddress = new SimpleVote();
            assetVoteContract = SimpleVoteInterface(assetVoteContractAddress);
            assetVoteContract.setOrganization(this);
            
            emit CreateVoteContract(assetVoteContractAddress);

            configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),START_VOTE_FUNCTION), msg.sender, OpMode.Add);
            configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),VOTE_FUNCTION), msg.sender, OpMode.Add);

            configureFunctionAddress(ASSET_VOTE_CONTRACT, assetVoteContractAddress, OpMode.Add);
        }
}

contract FakePerson is Execution {
    function() public payable {}
}

contract DAOTest is DSTest {
    FakeDAO dao;
    FakePerson tempPresident;
    FakePerson member1;
    FakePerson member2;
    FakePerson member3;
    uint96 asset;

    function setup() public {
        dao = new FakeDAO("dandan",new address[](0));
        assertEq(dao.getPresident(), this);

        tempPresident = new FakePerson();
        member1 = new FakePerson();
        member2 = new FakePerson();
        member3 = new FakePerson();
    }

    function testTransferPresident() public {
        setup();
        dao.transferPresidentRole(tempPresident);
        assertEq(dao.getPresident(), this);

        bool success = tempPresident.execute(dao, "confirmPresident()");
        assertTrue(success);
        assertEq(dao.getPresident(), tempPresident);

        success = tempPresident.execute(dao, "transferPresidentRole(address)", abi.encode(this));
        assertTrue(success);
        dao.confirmPresident();
        assertEq(dao.getPresident(), this);

        success = tempPresident.execute(dao, "transferPresidentRole(address)", abi.encode(tempPresident));
        assertTrue(!success);
    }

    function testInviteMembers() public {
        setup();
        dao.inviteNewMember(member1);
        bool success = member1.execute(dao, "joinNewMember()");
        assertTrue(success);

        success = member2.execute(dao, "joinNewMember()");
        assertTrue(!success);

        dao.inviteNewMember(member2);
        success = member2.execute(dao, "joinNewMember()");
        assertTrue(success);

        dao.inviteNewMember(member3);
        success = member3.execute(dao, "joinNewMember()");
        assertTrue(success);

        assertEq(dao.getMembers().length, 3);
        assertEq(dao.getMembers()[0],member1);
        assertEq(dao.getMembers()[1],member2);
        assertEq(dao.getMembers()[2],member3);
    }

    function testRemoveMember() public {
        testInviteMembers();
        dao.removeMember(member2);
        assertEq(dao.getMembers().length, 2);
        assertEq(dao.getMembers()[0],member1);
        assertEq(dao.getMembers()[1],member3);
    }

    function testCreateAssetFail() public {
        testInviteMembers();
        bool success = dao.call(abi.encodeWithSignature("createAsset(string,string,string,uint32,uint32,uint256)", "jack coin", "jc", "jack's first coin",0,1,100*10**8));
        assertTrue(!success);

        uint64 assetId = uint64(0) << 32 | uint64(dao.getOrganizationId());
        asset = uint96(assetId) << 32 | uint96(1);

        assertEq(flow.balance(dao, asset), 0);
    }

    function testCreateAssetVoteFinished() public {
        testInviteMembers();
        SimpleVote vote = SimpleVote(dao.getAssetVoteContract());
        vote.startVote("test vote", 2, 4, 66, 9999999999, bytes4(keccak256("createAsset(string,string,string,uint32,uint32,uint256)")), abi.encode("jack coin", "jc", "jack's first coin",0,1,100*10**8));

        member1.execute(vote, "vote(uint256,bool)", abi.encode(1,true));
        member2.execute(vote, "vote(uint256,bool)", abi.encode(1,true));
        member3.execute(vote, "vote(uint256,bool)", abi.encode(1,true));

        uint64 assetId = uint64(0) << 32 | uint64(dao.getOrganizationId());
        asset = uint96(assetId) << 32 | uint96(1);

        assertEq(flow.balance(dao, asset), 100*10**8);
    }

    function testCreateAssetVoteUnfinished() public {
        testInviteMembers();
        SimpleVote vote = SimpleVote(dao.getAssetVoteContract());
        vote.startVote("test vote", 2, 4, 66, 9999999999, bytes4(keccak256("createAsset(string,string,string,uint32,uint32,uint256)")), abi.encode("jack coin", "jc", "jack's first coin",0,1,100*10**8));

        member1.execute(vote, "vote(uint256,bool)", abi.encode(1,true));
        member2.execute(vote, "vote(uint256,bool)", abi.encode(1,true));
        member3.execute(vote, "vote(uint256,bool)", abi.encode(1,false));

        uint64 assetId = uint64(0) << 32 | uint64(dao.getOrganizationId());
        asset = uint96(assetId) << 32 | uint96(1);

        assertEq(flow.balance(dao, asset), 0);
    }

    function testMint() public {
        testCreateAssetVoteFinished();
        dao.mintAsset(1, 100*10**8);

        assertEq(flow.balance(dao, asset), 200*10**8);
    }

    function testTransfer() public {
        testMint();

        dao.transferAsset(0x668d5634afb9cfb064563b124bf6302ad78ed1cf40,asset,50*10**8);
        assertEq(flow.balance(dao, asset), 150*10**8);
        assertEq(flow.balance(0x668d5634afb9cfb064563b124bf6302ad78ed1cf40, asset), 50*10**8);
    }

}