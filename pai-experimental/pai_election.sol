pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/library/election.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

contract PISelection is Election,ACLSlave,DSMath {
    struct ElectionState {
        bool exist;
        bool executed;
        uint electionId;
        uint candidatesNumberLimit;
    }
    mapping(bytes => ElectionState) electionStates;

    uint electionStateId;
    mapping(uint => bytes) electionRole;

    uint constant public ONE_BLOCK_TIME = 5;
    uint public nominateLength = 7 days / ONE_BLOCK_TIME;
    uint public electionLength = 7 days / ONE_BLOCK_TIME;
    uint public qualification = RAY / 20;
    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        assettype = PAIDAO(master).PISGlobalId();
    }

    function createNewElectionType(bytes role, uint limit) public auth("PISVOTE") {
        require(!electionStates[role].exist);
        electionStateId = add(electionStateId,1);
        electionRole[electionStateId] = role;
        electionStates[role].exist = true;
        electionStates[role].candidatesNumberLimit = limit;
    }

    function updateTotalSupply() public {
        (,,,,, totalSupply) = PAIDAO(master).getAssetInfo(0);
    }

    function startElectionInternal(bytes electionRole) internal {
        require(electionStates[electionRole].exist);
        require(0 == electionStates[electionRole].electionId || nowBlock() > add(electionRecords[electionStates[electionRole].electionId].executionStartBlock, 1 days / ONE_BLOCK_Time));
        uint electionId = startElection(nominateLength, electionLength, qualification);
        electionRecords[electionId].electionRole = electionRole;
        electionStates[electionRole].electionId = electionId;
        nominateCandidates(electionId,master.getMembers(electionRole));
    }


    function startElectionByDirector(bytes electionRole) public auth("DIRECTOR") {
        startElectionInternal(electionRole);
    }

    function startElectionByPISHolder(bytes electionRole) public payable {
        updateTotalSupply();
        require(percent(msg.value, totalSupply) >= qualification);
        startElectionInternal(electionRole);
    }

    function nominateCandidate(uint electionIndex, address candidate) internal {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        if(candidate == 0x0){
            return;
        }
        if(election.candidates.contains(candidate)) {
            return;
        }
        require(nowBlock() >= election.nominateStartBlock);
        require(nowBlock() < election.electionStartBlock);
        for(uint i = 1; i < electionStateId; i++) {
            if(keccak256(electionRole[i]) != keccak256(election.electionRole)) {
                if(master.addressExist(electionRole[i], candidate)) {
                    return;
                }
                if(electionStates[electionRole[i]].electionId != 0 &&
                   false == electionStates[electionRole[i]].executed &&
                   nowBlock() < add(electionRecords[electionStates[electionRole[i]].electionId].executionStartBlock, 1 days / ONE_BLOCK_Time) &&
                   electionRecords[electionStates[electionRole[i]].electionId].candidates.contains(candidate)
                    ) {
                    return;
                }
            }
        }
        election.candidates.push(candidate);
        election.candidateSupportRates.push(0);
    }

    function nominateCandidates(uint electionIndex, address[] candidates) internal {
        for(uint i = 0; i < candidates.length; i++) {
            nominateCandidate(electionIndex,candidates[i]);
        }
    }

    function nominateCandidateByPIS(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        updateTotalSupply();
        require(msg.assettype == assettype);
        require(percent(msg.value, totalSupply) >= election.nominateQualification);
        nominateCandidate(electionIndex,candidate);
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateCandidatesByPIS(uint electionIndex, address[] candidates) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        uint length = candidates.length;
        require(length > 0);
        require(percent(msg.value, totalSupply) >= election.nominateQualification.mul(length));
        require(msg.assettype == assettype);
        nominateCandidates(electionIndex,candidates);
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateByDirectors(uint electionIndex, address[] candidates) public auth("DIRECTORVOTE") {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.electionStartBlock);
        require(nowBlock() < election.executionStartBlock);
        require(add(candidates.length, election.candidates.length) <= electionStates[election.electionRole].candidatesNumberLimit);
        //nominateCandidates(electionIndex,candidates);
    }

    function quit(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.nominateStartBlock);
        require(nowBlock() < election.electionStartBlock);
        require(election.candidates.contains(msg.sender));
        election.quit[msg.sender] = true;
    }

    function executeResult(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.executionStartBlock);
        require(!electionStates[election.electionRole].exist);
        if(!election.sorted) {
            processElectionResult(electionIndex);
        }
        uint len = master.getMemberLimit(election.electionRole);
        address[] tempAddr;
        for(uint i = 0; i < len; i++) {
            if (0 == electionRecords[electionIndex].candidateSupportRates[i]) {
                break;
            }
            tempAddr.push(electionRecords[electionIndex].candidates[i]);
        }
        master.resetMembers(tempAddr,election.electionRole);
        electionStates[election.electionRole].exist = true;
    }
}

