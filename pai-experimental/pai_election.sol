pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/library/election.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

contract PISelection is Election,ACLSlave,DSMath {
    mapping (uint => bool) public executed;
    mapping (uint => bytes) public electionRoles;
    mapping (bytes => uint) public candidatesNumberLimit;
    uint public nominateLength = 7 days / 5;
    uint public electionLength = 7 days / 5;
    uint public qualification = RAY / 20;
    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        assettype = PAIDAO(master).PISGlobalId();
    }

    function updateTotalSupply() public {
        (,,,,, totalPISSupply) = PAIDAO(master).getAssetInfo(0);
    }

    function startElectionByDirector(bytes electionRole) public auth("DIRECTOR") {
        updateTotalSupply();
        uint electionId = startElection(nominateLength, electionLength, qualification);
        electionRoles[electionId] = electionRole;
        candidatesNumberLimit[bytes("DIRECTOR")] = 20;
    }

    function startElectionByPISHolder(bytes electionRole) public payable {
        updateTotalSupply();
        require(percent(msg.value, totalSupply) >= qualification);
        uint electionId = startElection(nominateLength, electionLength, qualification);
        electionRoles[electionId] = electionRole;
    }

    function nominateByDirectors(uint electionIndex, address[] candidates) public auth("DIRECTORVOTE") {
        require(nowBlock() > sub(election.executionStartBlock, 3600 / 5));
        require(add(candidates.length, electionRecords[electionIndex].candidates.length) <= candidatesNumberLimit[electionRoles[electionId]]);
        nominateCandidatesByAuthroity(electionIndex,candidates);
    }

    function executeResult(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(nowBlock() >= election.executionStartBlock);
        require(!executed[electionIndex]);
        if(!election.sorted) {
            processElectionResult(electionIndex);
        }
        address[] memory tempAddr = getElectionCandidates(electionIndex);
        if(tempAddr.length > master.getMemberLimit(electionRoles[electionId])) {
            tempAddr.length = master.getMemberLimit(electionRoles[electionId]);
        }
        master.resetMembers(tempAddr,electionRoles[electionId]);
        executed[electionIndex] = true;
    }
}

