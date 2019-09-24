pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/library/election.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

contract PISelection is Election,ACLSlave,DSMath {
    mapping (uint => bool) public executed;
    mapping (uint => bytes) public electionRoles;
    mapping (bytes => uint) candidatesNumberLimit;

    uint public nominateLength = 7 days / 5;
    uint public electionLength = 7 days / 5;
    uint public qualification = RAY / 20;
    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        assettype = PAIDAO(master).PISGlobalId();
    }

    function setCandidatesLimit(bytes role, uint limits) public auth("PISVOTE") {
        candidatesNumberLimit[role] = limits;
    }

    function updateTotalSupply() public {
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);
    }

    function startElectionByDirector(bytes electionRole) public auth("DIRECTOR") {
        updateTotalSupply();
        uint electionId = startElection(nominateLength, electionLength, qualification);
        electionRoles[electionId] = electionRole;
    }

    function startElectionByPISHolder(bytes electionRole) public payable {
        updateTotalSupply();
        require(percent(msg.value, totalSupply) >= qualification);
        uint electionId = startElection(nominateLength, electionLength, qualification);
        electionRoles[electionId] = electionRole;
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateByDirectors(uint electionIndex, address[] candidates) public auth("DIRECTORVOTE") {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(add(candidates.length, election.candidates.length) <= candidatesNumberLimit[electionRoles[electionIndex]]);
        nominateCandidatesByAuthroity(electionIndex,candidates);
    }

    function becomeCandidates(uint electionIndex) public bytesAuth(electionRoles[electionIndex]){
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.nominateStartBlock);
        require(nowBlock() < election.electionStartBlock);
        require(!election.candidates.contains(msg.sender));
        election.candidates.push(msg.sender);
        election.candidateSupportRates.push(0);
    }

    function executeResult(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.executionStartBlock);
        require(!executed[electionIndex]);
        if(!election.sorted) {
            processElectionResult(electionIndex);
        }
        uint len = master.getMemberLimit(electionRoles[electionIndex]);
        if (0 == election.candidates.length) {
            return;
        }
        if (0 == len || len > election.candidates.length) {
            len = election.candidates.length;
        }
        address[] memory tempAddr = new address[](len);
        for(uint i = 0; i < len; i++) {
            tempAddr[i] = election.candidates[i];
        }
        master.resetMembers(tempAddr,electionRoles[electionIndex]);
        executed[electionIndex] = true;
    }
}

