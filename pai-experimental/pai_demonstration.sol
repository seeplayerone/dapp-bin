pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "../library/template.sol";
import "./3rd/math.sol";
import "../library/execution.sol";
import "../library/acl_slave.sol";
import "./pai_main.sol";
import "./pai_proposal.sol";
import "./pai_PISvote.sol";

contract Demonstration is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, CLOSED}
    uint public duration;
    uint public passProportion;
    uint public validityTerm = 1 days / 5;
    uint96 public ASSET_PIS;

    // vote event
    // event CreateVote(uint);
    // event ConductVote(uint, uint, VoteStatus);

    struct vote {
        uint proposalId;
        uint agreeVotes;
        uint startTime; /// vote start time, measured by block height
        bool executed;
        VoteStatus status;
    }
   
    /// all votes in this contract
    mapping(uint => vote) public votes;
    uint public lastVoteId = 0;
    string public preVoteContract;

    ProposalData public proposal;
    PISVote public nextVoteContract;

    constructor(address paiMainContract, address _proposal, address _nextVote, uint _passProportion, uint _duration, string preVote) {
        master = ACLMaster(paiMainContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
        proposal = ProposalData(_proposal);
        nextVoteContract = PISVote(_nextVote);
        passProportion = _passProportion;
        duration = _duration;
        preVoteContract = preVote;
        // passProportion = RAY * 2 / 3;
        // startProportion = RAY / 20;
        // pisVoteDuration = 10 days / 5;
    }

    /// @dev start a vote
    function startVoteByAuthroity(uint _proposalId, uint _startTime) public payable auth(preVoteContract) returns(uint) {
        return startVoteInternal(_proposalId,_startTime);
    }

    function startVoteInternal(uint _proposalId, uint _startTime) internal returns(uint) {
        require(0 == _startTime || _startTime >= height());
        lastVoteId = add(lastVoteId,1);
        uint startTime = 0 == _startTime ? height():_startTime;
        votes[lastVoteId].proposalId = _proposalId;
        votes[lastVoteId].startTime = startTime;
        return lastVoteId;
    }

    function updatePISVoteStatus(uint voteId) public {
        require(voteId <= lastVoteId, "vote not exist");
        vote storage v = votes[voteId];
        if(v.status > VoteStatus.ONGOING)
            return;
        if (height() < v.startTime) {
            v.status = VoteStatus.NOTSTARTED;
            return;
        }
        if (height() > add(v.startTime, duration)) {
            v.status = VoteStatus.CLOSED;
            return;
        }
        v.status = VoteStatus.ONGOING;
    }

    function pisVote(uint voteId) public payable {
        require(msg.assettype == ASSET_PIS);
        require(voteId <= lastVoteId, "vote not exist");
        updatePISVoteStatus(voteId);
        vote storage v = votes[voteId];
        require(VoteStatus.ONGOING == v.status, "vote not ongoing");
        v.agreeVotes = add(v.agreeVotes, msg.value);
        msg.sender.transfer(msg.value,ASSET_PIS);
        (,,,,,uint totalPISSupply) = PAIDAO(master).getAssetInfo(0);
        if(v.agreeVotes >= rmul(passProportion,totalPISSupply)) {
            nextVoteContract.startVoteByAuthroity(votes[voteId].proposalId,0);
            votes[voteId].executed = true;
        }
    }

    /// @dev callback function to invoke organization contract
    function invokeVote(uint voteId) public {
        ProposalData.ProposalItem[] memory items = proposal.getProposalItems(votes[voteId].proposalId);
        updatePISVoteStatus(voteId);
        require(votes[voteId].status == VoteStatus.CLOSED);
        require(false == votes[voteId].executed);
        require(height() < add(add(votes[voteId].startTime, duration),validityTerm));
        uint len = items.length;
        for(uint i = 0; i < len; i++) {
            execute(items[i].target,abi.encodePacked(items[i].func, items[i].param));
        }
        votes[voteId].executed = true;
    }

    function height() public view returns (uint256) {
        return block.number;
    }
}