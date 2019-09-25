pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract PISVoteStandard is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, APPROVED, REJECTED}
    enum VoteAttitude {AGREE,DISAGREE,ABSTAIN}
    uint public startProportion = RAY / 20;

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);

    struct Proposal {
        address target; /// call contract of vote result
        bytes4 func; /// functionHash of the callback function
        bytes param; /// parameters for the callback function
        bool executed; /// whether vote result is executed
        uint pisVoteId;
    }

    struct FuncData {
        uint passProportion;
        bytes4 func;
        uint pisVoteDuration;
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
    mapping(uint => FuncData) public voteFuncDatas;
    mapping(uint => Proposal) public voteProposals;
    uint public lastPISVoteId = 0;
    uint public lastAssignedProposalId = 0;
    uint public lastFuncDataId = 0;
    uint96 public ASSET_PIS;

    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
    }

    function addNewVoteParam(
        uint _passProportion,
        bytes4 _func,
        uint _pisVoteDuration
        ) public auth("PISVOTE") {
        lastFuncDataId = add(lastFuncDataId,1);
        voteFuncDatas[lastFuncDataId].passProportion = _passProportion;
        voteFuncDatas[lastFuncDataId].func = _func;
        voteFuncDatas[lastFuncDataId].pisVoteDuration = _pisVoteDuration;
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
            if(pv.agreeVotes > rmul(add(add(pv.agreeVotes,pv.disagreeVotes),pv.abstainVotes),pv.passProportion)) {
                pv.status = VoteStatus.APPROVED;
                return;
            }
            pv.status = VoteStatus.REJECTED;
            return;
        }
        pv.status = VoteStatus.ONGOING;
    }

    /// @dev start a vote
    function startProposal(uint FuncDataId,uint _startTime,address _targetContract,bytes _param) public payable returns(uint) {
        require(msg.assettype == ASSET_PIS);
        require(0 == _startTime || _startTime >= height());
        (,,,,,uint totalPISSupply) = PAIDAO(master).getAssetInfo(0);
        require(msg.value > rmul(startProportion,totalPISSupply));
        lastAssignedProposalId = add(lastAssignedProposalId,1);
        FuncData storage fd = voteFuncDatas[FuncDataId];
        uint startTime = 0 == _startTime ? height():_startTime;
        voteProposals[lastAssignedProposalId].target = _targetContract;
        voteProposals[lastAssignedProposalId].func = fd.func;
        voteProposals[lastAssignedProposalId].param = _param;
        voteProposals[lastAssignedProposalId].pisVoteId = startPISVote(fd.passProportion,startTime,fd.pisVoteDuration);
        msg.sender.transfer(msg.value,ASSET_PIS);
        return lastAssignedProposalId;
    }

    function pisVote(uint voteId, VoteAttitude attitude) public payable{
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
        execute(prps.target,abi.encodePacked(prps.func, prps.param));
        prps.executed = true;
    }

    function height() public view returns (uint256) {
        return block.number;
    }
}