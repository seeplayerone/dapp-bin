pragma solidity 0.4.25;

import "../election.sol";
import "../3rd/math.sol";
import "../3rd/test.sol";
import "../fake_btc_issuer.sol";

contract Fly {
    uint256  _era;

    constructor() public {
        _era = block.number;
    }

    function nowBlock() public view returns (uint256) {
        return _era == 0 ? block.number : _era;
    }

    function fly(uint age) public {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract FakePerson {
    function() public payable {}

    function execute(address target, string signature, bytes params, uint amount, uint assettype) returns (bool){
        bytes4 selector = bytes4(keccak256(signature));
        return target.call.value(amount, assettype)(abi.encodePacked(selector, params));        
    }

    function execute(address target, string signature, bytes params) returns (bool){
        bytes4 selector = bytes4(keccak256(signature));
        return target.call(abi.encodePacked(selector, params));        
    }
}

contract FlyElection is Election, Fly {
    constructor(bytes _role, uint _assettype) 
        public {
            init(_role, _assettype);
        }
}

contract ElectionTest is DSTest {
    uint constant public ONE_DAY_BLOCKS = 12 * 60 * 24;
    
    FlyElection elections;
    FakeBTCIssuer issuer;
    FakePerson[] persons;

    string public ROLE = "ADMIN";

    function setup() public returns (uint) {
        issuer = new FakeBTCIssuer();
        issuer.init("jack-sb");

        for(uint i = 1; i < 11; i ++) {
            FakePerson person = new FakePerson();
            issuer.mint(10**8 * i, address(person));
            persons.push(person);
        }

        FakePerson boss = new FakePerson();
        issuer.mint(10**8 * 20, address(boss));
        persons.push(boss);

        FakePerson bossWife = new FakePerson();
        issuer.mint(10**8 * 25, address(bossWife));
        persons.push(bossWife);

        elections = new FlyElection(bytes(ROLE), issuer.getAssetType());
        return elections.startElection(ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, 5 * 10**6, 10**10);
    }

    function testSetup() public {
        setup();
    }

    function testElectionCreated() public {
        uint index = setup();
        (uint a, uint b, uint c) = elections.getElectionRecord(index);
        assertEq(a, issuer.getAssetType());
        assertEq(b, 10**10);
        assertEq(c, 5 * 10**6);
        for(uint i = 0; i < 10; i ++) {
            assertEq(flow.balance(persons[i], issuer.getAssetType()), (i+1)*10**8);
        }
        assertEq(flow.balance(persons[10], issuer.getAssetType()), 10**8 * 20);
        assertEq(flow.balance(persons[11], issuer.getAssetType()), 10**8 * 25);        
    }

    function testNominateQualification() public {
        uint index = setup();
        for(uint i = 0; i < 12; i ++) {
            bool success = persons[i].execute(
                address(elections), 
                "nominateCandidateByAsset(uint256,address)", 
                abi.encode(index, address(persons[i])), 
                flow.balance(persons[i], issuer.getAssetType()), 
                issuer.getAssetType()
            );
            if(i < 4) {
                assertTrue(!success);
            } else {
                assertTrue(success);
            }
        }
    }

    function testNominationMultipleQualificationSuccess() public returns (uint){
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = persons[11].execute(
            address(elections),
            "nominateCandidatesByAsset(uint256,address[])",
            abi.encode(index, candidates), 
            flow.balance(persons[11], issuer.getAssetType()),
            issuer.getAssetType()
        );
        assertTrue(success);
        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 5);
        assertEq(b.length, 5);
        return index;
    }

    function testNominationMultipleQualificationFail() public {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = persons[10].execute(
            address(elections),
            "nominateCandidatesByAsset(uint256,address[])",
            abi.encode(index, candidates), 
            flow.balance(persons[10], issuer.getAssetType()),
            issuer.getAssetType()
        );
        assertTrue(!success);
    }

    function testNominationMultipleByAuthority() public returns (uint) {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = elections.call(abi.encodeWithSignature("nominateCandidatesByAuthority(uint256,address[])", index, candidates));
        assertTrue(success);

        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 5);
        assertEq(b.length, 5);

        return index;
    }

    function testNominationMultipleByAuthorityDirectly() public returns (uint) {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }

        elections.nominateCandidatesByAuthority(index, candidates);

        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 5);
        assertEq(b.length, 5);

        return index;
    }

    function testCancelNomination() public returns (uint) {
        uint index = testNominationMultipleByAuthorityDirectly();
        bool success = persons[2].execute(address(elections), "cancelNomination(uint256)", abi.encode(index));
        assertTrue(success);

        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 4);
        assertEq(b.length, 4);

        assertEq(elections.getElectionCandidates(index)[0], address(persons[0]));
        assertEq(elections.getElectionCandidates(index)[1], address(persons[1]));
        assertEq(elections.getElectionCandidates(index)[2], address(persons[4]));
        assertEq(elections.getElectionCandidates(index)[3], address(persons[3]));
    }

    function testVoteForCandidates() public returns (uint) {
        uint index = testNominationMultipleByAuthorityDirectly();
        elections.fly(ONE_DAY_BLOCKS * 2 + 1);

        bool success;

        for(uint i = 0; i < 5; i ++) {
            success = mVoteForN(index, i, i);
            assertTrue(success);
        }

        for(i = 5; i < 10; i ++) {
            success = mVoteForN(index, i, i - 5);
            assertTrue(success);
        }

        success = mVoteForN(index, 10, 1);
        assertTrue(success);

        success = mVoteForN(index, 11, 3);
        assertTrue(success);

        uint[] memory candidateSupportRates = elections.getElectionCandidateSupportRates(index);
        assertEq(candidateSupportRates[0], 7 * 10**6);
        assertEq(candidateSupportRates[1], 29 * 10**6);
        assertEq(candidateSupportRates[2], 11 * 10**6);
        assertEq(candidateSupportRates[3], 38 * 10**6);
        assertEq(candidateSupportRates[4], 15 * 10**6);

        return index;
    }

    function mVoteForN(uint index, uint m, uint n) public returns (bool) {
        return persons[m].execute(
            address(elections),
            "voteForCandidate(uint256,address)",
            abi.encode(index, address(persons[n])),
            flow.balance(persons[m], issuer.getAssetType()),
            issuer.getAssetType()
        );
    }

    function testProcessResult() public returns (uint){
        uint index = testVoteForCandidates();

        bool success = elections.call(abi.encodeWithSignature("processElectionResult(uint256)", index));
        assertTrue(!success);

        elections.fly(ONE_DAY_BLOCKS * 2 + 1);
        success = elections.call(abi.encodeWithSignature("processElectionResult(uint256)", index));
        assertTrue(success);

        uint[] memory candidateSupportRates = elections.getElectionCandidateSupportRates(index);
        assertEq(candidateSupportRates[0], 38 * 10**6);
        assertEq(candidateSupportRates[1], 29 * 10**6);
        assertEq(candidateSupportRates[2], 15 * 10**6);
        assertEq(candidateSupportRates[3], 11 * 10**6);
        assertEq(candidateSupportRates[4], 7 * 10**6);

        address[] memory candidates = elections.getElectionCandidates(index);
        assertEq(candidates[0], persons[3]);
        assertEq(candidates[1], persons[1]);
        assertEq(candidates[2], persons[4]);
        assertEq(candidates[3], persons[2]);
        assertEq(candidates[4], persons[0]);

        return index;
    }

    function testStart2rdNominationFail() public {
        testVoteForCandidates();

        bool success = elections.call(abi.encodeWithSignature("startElection(uint256,uint256,uint256,uint256,uint256)",ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, 5 * 10**6, 10**10));
        assertTrue(!success);
    }

    function testStart2rdNominationAfterProcess() public {
        testProcessResult();

        bool success = elections.call(abi.encodeWithSignature("startElection(uint256,uint256,uint256,uint256,uint256)",ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, 5 * 10**6, 10**10));
        assertTrue(success);
    }

    function testCeaseFail() public {
        uint index = testVoteForCandidates();
        bool success = elections.call("ceaseElection(uint256)",index);
        assertTrue(!success);
    }

    function testCeaseSuccess() public {
        uint index = testVoteForCandidates();
        elections.fly(ONE_DAY_BLOCKS * 4 + 1);
        elections.ceaseElection(index);
    }

    function testStart2rdNominationAfterCease() public {
        testCeaseSuccess();
        bool success = elections.call(abi.encodeWithSignature("startElection(uint256,uint256,uint256,uint256,uint256)",ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, 5 * 10**6, 10**10));
        assertTrue(success);
    }
}



