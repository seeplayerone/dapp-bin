pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "../library/template.sol";
import "../library/utils/ds_math.sol";
import "../library/utils/execution.sol";
import "../library/acl_slave.sol";
import "./pai_main.sol";
import "./pai_proposal.sol";
import "./pai_PISvote.sol";


contract DIRVote is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, CLOSED}
    enum VoteAttitude {AGREE,DISAGREE}
    enum ExectionType {DIRECTLY,TRIGGERNEWVOTE}
    uint public duration;
    uint public passProportion;

    struct vote {
        uint proposalId;
        uint agreeVotes;
        uint disagreeVotes;
        uint startTime; /// vote start time, measured by block height
        mapping(address => bool) alreadyVoted;
        bool executed;
        ExectionType execType; 
        VoteStatus status;
    }
   
    /// all votes in this contract
    mapping(uint => vote) public votes;
    uint public lastVoteId = 0;
    string public director;
    string public AnotherOriginator;

    ProposalData public proposal;
    PISVote public nextVoteContract;

    constructor(address paiMainContract, address _proposal, address _nextVote, uint _passProportion, uint _duration, string _director, string _originator) {
        master = ACLMaster(paiMainContract);
        proposal = ProposalData(_proposal);
        nextVoteContract = PISVote(_nextVote);
        passProportion = _passProportion;
        duration = _duration;
        director = _director;
        AnotherOriginator = _originator;
        // passProportion = RAY * 2 / 3;
        // startProportion = RAY / 20;
        // pisVoteDuration = 10 days / 5;
    }

    function startVote(uint _proposalId, uint _startTime, ExectionType _execType) public auth(director) returns(uint) {
        return startVoteInternal(_proposalId,_startTime,_execType);
    }

    function startVoteByOthers(uint _proposalId, uint _startTime, ExectionType _execType) public auth(AnotherOriginator) returns(uint) {
        return startVoteInternal(_proposalId,_startTime,_execType);
    }

    function startVoteInternal(uint _proposalId, uint _startTime,ExectionType _execType) internal returns(uint) {
        require(0 == _startTime || _startTime >= height());
        lastVoteId = add(lastVoteId,1);
        uint startTime = 0 == _startTime ? height():_startTime;
        votes[lastVoteId].proposalId = _proposalId;
        votes[lastVoteId].startTime = startTime;
        votes[lastVoteId].execType = _execType;
        return lastVoteId;
    }

    function updateDirectorVoteStatus(uint voteId) public {
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

   function dirVote(uint voteId, VoteAttitude attitude) public auth(director) {
        require(voteId <= lastVoteId, "vote not exist");
        updateDirectorVoteStatus(voteId);
        vote storage v = votes[voteId];
        require(!v.alreadyVoted[msg.sender]);
        require(VoteStatus.ONGOING == v.status, "vote not ongoing");
        v.alreadyVoted[msg.sender] = true;
        if (VoteAttitude.AGREE == attitude) {
            v.agreeVotes = add(v.agreeVotes, 1);
            if(v.agreeVotes >= rmul(passProportion,master.getMemberLimit(bytes(director)))) {
                invokeVote(voteId);
            }
        } else {
            v.disagreeVotes = add(v.disagreeVotes,1);
        }
    }

    /// @dev callback function to invoke organization contract
    function invokeVote(uint voteId) internal {
        ProposalData.ProposalItem[] memory items = proposal.getProposalItems(votes[voteId].proposalId);
        updateDirectorVoteStatus(voteId);
        require(false == votes[voteId].executed);
        if(ExectionType.TRIGGERNEWVOTE == votes[voteId].execType) {
            nextVoteContract.startVoteByAuthroity(votes[voteId].proposalId,0);
            votes[voteId].executed = true;
            return;
        }
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