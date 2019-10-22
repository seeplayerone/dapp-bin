pragma solidity 0.4.25;

import "../library/acl_slave.sol";
import "../library/election.sol";
import "./pai_main.sol";
import "./3rd/math.sol";

contract PAIElectionBase is Election,ACLSlave,DSMath {
    uint constant public ONE_BLOCK_TIME = 5;

    uint public nominationLength = 7 days / ONE_BLOCK_TIME;
    uint public electionLength = 7 days / ONE_BLOCK_TIME;
    uint public executionLength = 7 days / ONE_BLOCK_TIME;
    uint public qualification = 5 * 10**6;

    string public WINNER;
    string public BACKUP;

    uint public totalSupply;

    struct Extra {
        /// target candidate count
        uint alpha;
        /// target backup count
        uint beta;
        /// relevant elections
        PAIElectionBase[] relevantElections;
    }

    mapping (uint=>Extra) extras;

    constructor(address pisContract, string winnerRole, string backupRole) public {
        master = ACLMaster(pisContract);

        assettype = PAIDAO(master).PISGlobalId();
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);  

        WINNER = winnerRole;
        BACKUP = backupRole;
        role = bytes(WINNER);
    }

    /// TODO acl
    function startElection(uint _alpha, uint _beta) public returns (uint) {
        /// update totalSupply for every election
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);  

        uint index = startElection(nominationLength, electionLength, executionLength, qualification, totalSupply);
        Extra storage extra = extras[index];
        extra.alpha = _alpha;
        extra.beta = _beta;

        address[] memory oldman = master.getMembers(bytes(WINNER));
        if(oldman.length > 0) {
            nominateCandidatesByAuthority(index, master.getMembers(bytes(WINNER)));
        }
        return index;
    }

    function startElectionSupplement(uint _alpha, uint _beta) public returns (uint) {
        /// update totalSupply for every election
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);  

        uint index = startElection(nominationLength, electionLength, executionLength, qualification, totalSupply);
        Extra storage extra = extras[index];
        extra.alpha = _alpha;
        extra.beta = _beta;

        return index;
    }

    function setRelevantElections(PAIElectionBase[] eles) public active {
        extras[currentIndex].relevantElections = eles;
    }

    function nominateCandidateByAsset(address candidate) public payable active {
        for(uint i = 0; i < extras[currentIndex].relevantElections.length; i ++) {
            require(!extras[currentIndex].relevantElections[i].getActiveCandidates().contains(candidate));
        }
        nominateCandidateByAsset(currentIndex, candidate);
    }

    function nominateCandidatesByAsset(address[] candidates) public payable active {
        for(uint i = 0; i < extras[currentIndex].relevantElections.length; i ++) {
            for(uint j = 0; j < candidates.length; j ++) {
                require(!extras[currentIndex].relevantElections[i].getActiveCandidates().contains(candidates[j]));
            }
        }
        nominateCandidatesByAsset(currentIndex, candidates);
    }

    /// TODO acl
    function nominateCandidatesByFoundingTeam(address[] cans) public active {
        ElectionRecord storage election = electionRecords[currentIndex];
        uint len = election.candidates.length;
        uint delta = cans.length;
        require(len < extras[currentIndex].alpha);
        require(len + delta >= extras[currentIndex].alpha);
        require(len + delta <= extras[currentIndex].alpha + extras[currentIndex].beta);
        nominateCandidatesByAuthority(currentIndex, cans);
    }

    /// TODO acl
    function processElectionResult() public active {
        ElectionRecord storage election = electionRecords[currentIndex];
        uint len = election.candidates.length;
        require(len >= extras[currentIndex].alpha);

        processElectionResult(currentIndex);

        address[] memory directors = new address[](extras[currentIndex].alpha);
        for(uint i = 0; i < extras[currentIndex].alpha; i++) {
            directors[i] = election.candidates[i];
        }
        master.resetMembers(directors, bytes(WINNER));

        if(len > extras[currentIndex].alpha) {
            address[] memory backups = new address[](len-extras[currentIndex].alpha);
            for(i = extras[currentIndex].alpha; i < len; i ++) {
                backups[i-extras[currentIndex].alpha] = election.candidates[i];
            }
            master.resetMembers(backups, bytes(BACKUP));
        }
    }

    /// TODO acl
    function ceaseElection() public active {
        ceaseElection(currentIndex);   
    }

    function getActiveCandidates() public view returns (address[]) {
        if(currentIndex == 0) {
            return new address[](0);
        }

        ElectionRecord storage election = electionRecords[currentIndex];
        if(election.created && !election.processed && !election.ceased) {
            return election.candidates;
        }

        return new address[](0);
    }

    modifier active() {
        require(currentIndex > 0);
        ElectionRecord storage election = electionRecords[currentIndex];
        require(election.created);
        require(!election.processed);
        require(!election.ceased);

        _;
    }
}