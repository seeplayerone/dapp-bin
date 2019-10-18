pragma solidity 0.4.25;

import "../library/acl_slave.sol";
import "../library/election.sol";
import "./pai_main.sol";
import "./3rd/math.sol";

contract PAIElectionDirector is Election,ACLSlave,DSMath {
    uint constant public ONE_BLOCK_TIME = 5;

    uint public nominationLength = 7 days / ONE_BLOCK_TIME;
    uint public electionLength = 7 days / ONE_BLOCK_TIME;
    uint public executionLength = 7 days / ONE_BLOCK_TIME;
    uint public qualification = 5 * 10**6;

    string public DIRECTOR = "PAI-DIRECTOR";
    string public BACKUP = "PAI-DIRECTOR-BACKUP";

    uint public totalSupply;

    /// target candidate count
    uint public alpha;
    /// target backup count
    uint public beta;

    constructor(address pisContract) public {
        master = ACLMaster(pisContract);

        assettype = PAIDAO(master).PISGlobalId();
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);  
        role = bytes(DIRECTOR);

        alpha = 4;
        beta = 3;
    }

    /// TODO acl
    function startElection() public returns (uint) {
        uint index = startElection(nominationLength, electionLength, executionLength, qualification, totalSupply);
        address[] memory oldman = master.getMembers(bytes(DIRECTOR));
        if(oldman.length > 0) {
            nominateCandidatesByAuthority(index, master.getMembers(bytes(DIRECTOR)));
        }
        return index;
    }

    /// TODO acl
    function nominateCandidatesByFoundingTeam(address[] cans) public {
        uint index = currentElectionIndex - 1;
        require(index > 0);
        ElectionRecord storage election = electionRecords[index];
        uint len = election.candidates.length;
        uint delta = cans.length;
        require(len < alpha);
        require(len + delta >= alpha);
        require(len + delta <= alpha + beta);
        nominateCandidatesByAuthority(index, cans);
    }

    /// TODO acl
    function processElectionResult() public {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        ElectionRecord storage election = electionRecords[index];
        uint len = election.candidates.length;
        require(len >= alpha);

        processElectionResult(index);

        address[] memory directors = new address[](alpha);
        for(uint i = 0; i < alpha; i++) {
            directors[i] = election.candidates[i];
        }
        master.resetMembers(directors, bytes(DIRECTOR));

        if(len > alpha) {
            address[] memory backups = new address[](len-alpha);
            for(i = alpha; i < len; i ++) {
                backups[i-alpha] = election.candidates[i];
            }
            master.resetMembers(backups, bytes(BACKUP));
        }
    }

    /// TODO acl
    function ceaseElection() public {
        uint index = currentElectionIndex - 1;
        require(index > 0);

        ceaseElection(index);   
    }
}