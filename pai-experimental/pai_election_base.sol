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
        uint index = currentElectionIndex - 1;
        extras[index].relevantElections = eles;
    }

    function nominateCandidateByAsset(address candidate) public payable active {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        for(uint i = 0; i < extras[index].relevantElections.length; i ++) {
            require(!extras[index].relevantElections[i].getActiveCandidates().contains(candidate));
        }
        nominateCandidateByAsset(currentElectionIndex.sub(1), candidate);
    }

    function nominateCandidatesByAsset(address[] candidates) public payable active {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        for(uint i = 0; i < extras[index].relevantElections.length; i ++) {
            for(uint j = 0; j < candidates.length; j ++) {
                require(!extras[index].relevantElections[i].getActiveCandidates().contains(candidates[j]));
            }
        }
        nominateCandidatesByAsset(currentElectionIndex.sub(1), candidates);
    }

    /// TODO acl
    function nominateCandidatesByFoundingTeam(address[] cans) public active {
        uint index = currentElectionIndex - 1;
        require(index > 0);
        ElectionRecord storage election = electionRecords[index];
        uint len = election.candidates.length;
        uint delta = cans.length;
        require(len < extras[index].alpha);
        require(len + delta >= extras[index].alpha);
        require(len + delta <= extras[index].alpha + extras[index].beta);
        nominateCandidatesByAuthority(index, cans);
    }

    /// TODO acl
    function processElectionResult() public active {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        ElectionRecord storage election = electionRecords[index];
        uint len = election.candidates.length;
        require(len >= extras[index].alpha);

        processElectionResult(index);

        address[] memory directors = new address[](extras[index].alpha);
        for(uint i = 0; i < extras[index].alpha; i++) {
            directors[i] = election.candidates[i];
        }
        master.resetMembers(directors, bytes(WINNER));

        if(len > extras[index].alpha) {
            address[] memory backups = new address[](len-extras[index].alpha);
            for(i = extras[index].alpha; i < len; i ++) {
                backups[i-extras[index].alpha] = election.candidates[i];
            }
            master.resetMembers(backups, bytes(BACKUP));
        }
    }

    /// TODO acl
    function ceaseElection() public active {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        ceaseElection(index);   
    }

    function getActiveCandidates() public view returns (address[]) {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        ElectionRecord storage election = electionRecords[index];
        if(election.created && !election.processed && !election.ceased) {
            return election.candidates;
        }

        return new address[](0);
    }

    modifier active() {
        uint index = currentElectionIndex - 1;
        require(index > 0);
        ElectionRecord storage election = electionRecords[index];
        require(election.created);
        require(!election.processed);
        require(!election.ceased);

        _;
    }
}