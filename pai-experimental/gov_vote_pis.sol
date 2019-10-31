pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "../library/template.sol";
import "../library/utils/execution.sol";
import "../library/acl_slave.sol";
import "./pis_main.sol";
import "./gov_proposal.sol";

contract PISVote is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, APPROVED, REJECTED}
    enum VoteAttitude {AGREE,DISAGREE,ABSTAIN}
    uint public startProportion;
    uint public duration;
    uint public passProportion;
    uint public validityPeriod = 1 days / 5;
    uint96 public ASSET_PIS;

    struct vote {
        uint proposalId;
        uint agreeVotes;
        uint disagreeVotes;
        uint abstainVotes;
        uint startTime; /// vote start time, measured by block height
        bool executed;
        VoteStatus status;
    }
   
    /// all votes in this contract
    mapping(uint => vote) public votes;
    uint public lastVoteId = 0;
    string public previousVoteContract;

    ProposalData public proposal;

    constructor(address pisContract, address _proposal, uint _passProportion, uint _startProportion, uint _duration, string _previousVote) public {
        master = ACLMaster(pisContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
        proposal = ProposalData(_proposal);
        passProportion = _passProportion;
        startProportion = _startProportion;
        duration = _duration;
        previousVoteContract = _previousVote;
    }

    /// @dev start a vote
    function startVote(uint _proposalId, uint _startTime) public payable returns(uint) {
        require(msg.assettype == ASSET_PIS);
        require(msg.value > rmul(startProportion,PAIDAO(master).totalSupply()));
        msg.sender.transfer(msg.value,ASSET_PIS);
        return startVoteInternal(_proposalId,_startTime);
    }

    function startVoteByAuthroity(uint _proposalId, uint _startTime) public auth(previousVoteContract) returns(uint) {
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
            if(0 == v.agreeVotes || v.agreeVotes < rmul(add(add(v.agreeVotes,v.disagreeVotes),v.abstainVotes),passProportion)) {
                v.status = VoteStatus.REJECTED;
                return;
            }
            v.status = VoteStatus.APPROVED;
            return;
        }
        v.status = VoteStatus.ONGOING;
    }

    function pisVote(uint voteId, VoteAttitude attitude) public payable {
        require(msg.assettype == ASSET_PIS);
        require(voteId <= lastVoteId, "vote not exist");
        updatePISVoteStatus(voteId);
        vote storage v = votes[voteId];
        require(VoteStatus.ONGOING == v.status, "vote not ongoing");
        if (VoteAttitude.AGREE == attitude) {
            v.agreeVotes = add(v.agreeVotes, msg.value);
        } else if (VoteAttitude.DISAGREE == attitude) {
            v.disagreeVotes = add(v.disagreeVotes,msg.value);
        } else {
            v.abstainVotes = add(v.abstainVotes,msg.value);
        }
        msg.sender.transfer(msg.value,ASSET_PIS);
    }

    function invokeVote(uint voteId) public {
        ProposalData.ProposalItem[] memory items = proposal.getProposalItems(votes[voteId].proposalId);
        updatePISVoteStatus(voteId);
        require(votes[voteId].status == VoteStatus.APPROVED);
        require(false == votes[voteId].executed);
        require(height() < add(add(votes[voteId].startTime, duration),validityPeriod));
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