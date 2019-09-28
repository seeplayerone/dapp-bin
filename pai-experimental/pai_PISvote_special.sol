pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract PISVoteSpecial is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, APPROVED, REJECTED}
    enum VoteAttitude {AGREE,DISAGREE,ABSTAIN}
    uint public passProportion = RAY * 2 / 3;
    uint public startProportion = RAY / 20;
    uint public pisVoteDuration = 10 days / 5;

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);

    struct Proposal {
        bytes32 attachmentHash;
        Order[] orders;
        bool executed; /// whether vote result is executed
        uint pisVoteId;
    }

    struct Order {
        address target; /// call contract of vote result
        bytes4 func; /// functionHash of the callback function
        bytes param; /// parameters for the callback function
    }

    struct PISVote {
        uint agreeVotes;
        uint disagreeVotes;
        uint abstainVotes;
        uint passProportion; ///in RAY;
        uint startTime; /// vote start time, measured by block height
        uint duration;  /// vote end time, measured by block height
        VoteStatus status;
    }
   
    /// all votes in this contract
    mapping(uint => PISVote) public pisVotes;
    mapping(uint => Proposal) public voteProposals;
    uint public lastPISVoteId = 0;
    uint public lastAssignedProposalId = 0;
    uint96 public ASSET_PIS;

    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
    }

    function startPISVote(uint _passProportion,uint _startTime,uint _duration) internal returns(uint) {
        lastPISVoteId = add(lastPISVoteId,1);
        pisVotes[lastPISVoteId].passProportion = _passProportion;
        pisVotes[lastPISVoteId].startTime = _startTime;
        pisVotes[lastPISVoteId].duration = _duration;
        return lastPISVoteId;
    }

    function updatePISVoteStatus(uint voteId) public {
        require(voteId <= lastPISVoteId, "vote not exist");
        PISVote storage pv = pisVotes[voteId];
        if(pv.status > VoteStatus.ONGOING)
            return;
        if (height() < pv.startTime) {
            pv.status = VoteStatus.NOTSTARTED;
            return;
        }
        if (height() > add(pv.startTime, pv.duration)) {
            if(0 == pv.agreeVotes || pv.agreeVotes < rmul(add(add(pv.agreeVotes,pv.disagreeVotes),pv.abstainVotes),pv.passProportion)) {
                pv.status = VoteStatus.REJECTED;
                return;
            }
            pv.status = VoteStatus.APPROVED;
            return;
        }
        pv.status = VoteStatus.ONGOING;
    }

    /// @dev start a vote
    function startProposal(bytes32 _attachmentHash, uint _startTime, Order[] memory _orders) public returns(uint) {
        //require(msg.assettype == ASSET_PIS);
        //require(0 == _startTime || _startTime >= height());
        //(,,,,,uint totalPISSupply) = PAIDAO(master).getAssetInfo(0);
        //require(msg.value > rmul(startProportion,totalPISSupply));
        lastAssignedProposalId = add(lastAssignedProposalId,1);
        //uint startTime = 0 == _startTime ? height():_startTime;
        voteProposals[lastAssignedProposalId].attachmentHash = _attachmentHash;
        uint len = _orders.length;
        for(uint i = 0; i < len; i++) {
            voteProposals[lastAssignedProposalId].orders.push(_orders[i]);
        }
        //voteProposals[lastAssignedProposalId].pisVoteId = startPISVote(passProportion,startTime,pisVoteDuration);
        //msg.sender.transfer(msg.value,ASSET_PIS);
        return lastAssignedProposalId;
    }

    function pisVote(uint voteId, VoteAttitude attitude) public payable {
        require(msg.assettype == ASSET_PIS);
        require(voteId <= lastPISVoteId, "vote not exist");
        updatePISVoteStatus(voteId);
        PISVote storage pv = pisVotes[voteId];
        require(VoteStatus.ONGOING == pv.status, "vote not ongoing");
        if (VoteAttitude.AGREE == attitude) {
            pv.agreeVotes = add(pv.agreeVotes, msg.value);
        } else if (VoteAttitude.DISAGREE == attitude) {
            pv.disagreeVotes = add(pv.disagreeVotes,msg.value);
        } else {
            pv.abstainVotes = add(pv.abstainVotes,msg.value);
        }
        msg.sender.transfer(msg.value,ASSET_PIS);
    }

    /// @dev callback function to invoke organization contract
    function invokeProposal(uint proposalId) public {
        require(proposalId <= lastAssignedProposalId, "proposal not exist");
        Proposal storage prps = voteProposals[proposalId];
        updatePISVoteStatus(prps.pisVoteId);
        require(pisVotes[prps.pisVoteId].status == VoteStatus.APPROVED);
        require(false == prps.executed);
        uint len = prps.orders.length;
        for(uint i = 0; i < len; i++) {
            execute(prps.orders[i].target,abi.encodePacked(prps.orders[i].func, prps.orders[i].param[i]));
        }
        prps.executed = true;
    }

    function height() public view returns (uint256) {
        return block.number;
    }
}