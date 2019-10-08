pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/election.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/fake_btc_issuer.sol";

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
    
}

contract ElectionTest is DSTest {
    uint constant public ONE_DAY_BLOCKS = 12 * 60 * 24;
    
    FlyElection elections;
    FakeBTCIssuer issuer;
    FakePerson[] persons;

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

        elections = new FlyElection();
        return elections.startElection(ONE_DAY_BLOCKS * 2, ONE_DAY_BLOCKS * 2, address(issuer), 5 * 10**6);
    }

    function testSetup() {
        setup();
    }

    function testElectionCreated() {
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

    function testNominateQualification() {
        uint index = setup();
        for(uint i = 0; i < 12; i ++) {
            bool success = persons[i].execute(
                address(elections), 
                "nominateCandidate(uint256,address)", 
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

    function testNominationMultipleQualificationSuccess() returns (uint){
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = persons[11].execute(
            address(elections),
            "nominateCandidates(uint256,address[])",
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

    function testNominationMultipleQualificationFail() {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = persons[10].execute(
            address(elections),
            "nominateCandidates(uint256,address[])",
            abi.encode(index, candidates), 
            flow.balance(persons[10], issuer.getAssetType()),
            issuer.getAssetType()
        );
        assertTrue(!success);
    }

    function testNominationMultipleByAuthority() returns (uint) {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }
        bool success = elections.call(abi.encodeWithSignature("nominateCandidatesByAuthroity(uint256,address[])", index, candidates));
        assertTrue(!success);

        elections.fly(ONE_DAY_BLOCKS * 2 + 1);
        success = elections.call(abi.encodeWithSignature("nominateCandidatesByAuthroity(uint256,address[])", index, candidates));
        assertTrue(success);

        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 5);
        assertEq(b.length, 5);

        return index;
    }

    function testNominationMultipleByAuthorityDirectly() returns (uint) {
        uint index = setup();
        address[] memory candidates = new address[](5);
        for(uint i = 0; i < 5; i ++) {
            candidates[i] = address(persons[i]);
        }

        elections.fly(ONE_DAY_BLOCKS * 2 + 1);
        elections.nominateCandidatesByAuthroity(index, candidates);

        address[] memory a = elections.getElectionCandidates(index);
        uint[] memory b = elections.getElectionCandidateSupportRates(index);
        assertEq(a.length, 5);
        assertEq(b.length, 5);

        return index;
    }

    function testVoteForCandidates() returns (uint) {
        uint index = testNominationMultipleByAuthorityDirectly();

        bool success;
        // bool success = mVoteForN(index, 0, 0);
        // assertTrue(!success);

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

    function mVoteForN(uint index, uint m, uint n) returns (bool) {
        return persons[m].execute(
            address(elections),
            "voteForCandidate(uint256,address)",
            abi.encode(index, address(persons[n])),
            flow.balance(persons[m], issuer.getAssetType()),
            issuer.getAssetType()
        );
    }

    function testProcessResult() {
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
    }
}



