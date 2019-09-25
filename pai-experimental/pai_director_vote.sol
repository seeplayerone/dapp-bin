pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract DirectorVoteContract is DSMath, Execution, Template, ACLSlave {

    enum VoteStatus {NOTSTARTED, ONGOING, APPROVED, REJECTED}
    enum VoteAttitude {AGREE,DISAGREE,ABSTAIN}

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);

    struct Proposal {
        address target; /// call contract of vote result
        bytes4 func; /// functionHash of the callback function
        bytes param; /// parameters for the callback function
        bool executed; /// whether vote result is executed
        uint directorVoteId;
        uint pisVoteId;
    }

    struct FuncData {
        uint passVotes;
        uint passProportion;
        bytes4 func;
        uint directorVoteDuration;
        uint pisVotelastDuration;
    }

    struct DirectorVote {
        uint agreeVotes;
        uint disagreeVotes;
        uint passVotes;
        uint startTime; /// vote start time, measured by block height
        uint duration;  /// vote end time, measured by block height
        address[] alreadyVoted;
        VoteStatus status;
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
    mapping(uint => DirectorVote) public directorVotes;
    mapping(uint => PISVote) public pisVotes;
    mapping(uint => FuncData) public voteFuncDatas;
    mapping(uint => Proposal) public voteProposals;
    uint public lastDirectorVoteId = 0;
    uint public lastPISVoteId = 0;
    uint public lastAssignedProposalId = 0;
    uint public lastFuncDataId = 0;
    uint96 public ASSET_PIS;

    constructor(address paiMainContract) {
        master = ACLMaster(paiMainContract);
        ASSET_PIS = PAIDAO(master).PISGlobalId();
    }

    function addNewVoteParam(
        uint _passVotes,
        uint _passProportion,
        bytes4 _func,
        uint _directorVoteDuration,
        uint _pisVotelastDuration
        ) public auth("PISVOTE") {
        lastFuncDataId = add(lastFuncDataId,1);
        voteFuncDatas[lastFuncDataId].passVotes = _passVotes;
        voteFuncDatas[lastFuncDataId].passProportion = _passProportion;
        voteFuncDatas[lastFuncDataId].func = _func;
        voteFuncDatas[lastFuncDataId].directorVoteDuration = _directorVoteDuration;
        voteFuncDatas[lastFuncDataId].pisVotelastDuration = _pisVotelastDuration;
    }

    function startDirectorVote(uint _passVotes,uint _startTime,uint _duration) internal returns(uint) {
        lastDirectorVoteId = add(lastDirectorVoteId,1);
        directorVotes[lastDirectorVoteId].passVotes = _passVotes;
        directorVotes[lastDirectorVoteId].startTime = _startTime;
        directorVotes[lastDirectorVoteId].duration = _duration;
        updateDirectorVoteStatus(lastDirectorVoteId);
        return lastDirectorVoteId;
    }

    function updateDirectorVoteStatus(uint voteId) public {
        require(voteId <= lastDirectorVoteId, "vote not exist");
        DirectorVote storage dv = directorVotes[voteId];
        if(dv.status > VoteStatus.ONGOING)
            return;
        if (height() < dv.startTime) {
            dv.status = VoteStatus.NOTSTARTED;
            return;
        }
        if (height() > add(dv.startTime, dv.duration)) {
            if (dv.agreeVotes >= dv.passVotes) {
                dv.status = VoteStatus.APPROVED;
                return;
            }
            dv.status = VoteStatus.REJECTED;
            return;
        }
        dv.status = VoteStatus.ONGOING;
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
            //there is a big difference between normal voting and announce voting. When nobody participates, the result of normal voting is rejected but the
            //result of announce voting is approved.
            if(pv.agreeVotes >= rmul(add(add(pv.agreeVotes,pv.disagreeVotes),pv.abstainVotes),pv.passProportion)) {
                pv.status = VoteStatus.APPROVED;
                return;
            }
            pv.status = VoteStatus.REJECTED;
            return;
        }
        pv.status = VoteStatus.ONGOING;
    }

    /// @dev start a vote
    function startProposal(uint FuncDataId,uint _startTime,address _targetContract,bytes _param) public auth("DIRECTOR") returns(uint) {
        require(0 == _startTime || _startTime >= height());
        lastAssignedProposalId = add(lastAssignedProposalId,1);
        FuncData storage fd = voteFuncDatas[FuncDataId];
        uint startTime = 0 == _startTime ? height():_startTime;
        voteProposals[lastAssignedProposalId].target = _targetContract;
        voteProposals[lastAssignedProposalId].func = fd.func;
        voteProposals[lastAssignedProposalId].param = _param;
        voteProposals[lastAssignedProposalId].directorVoteId = startDirectorVote(fd.passVotes,startTime,fd.directorVoteDuration);
        if(fd.pisVotelastDuration != 0)
            voteProposals[lastAssignedProposalId].pisVoteId = startPISVote(fd.passProportion,add(startTime,fd.directorVoteDuration),fd.pisVotelastDuration);
        return lastAssignedProposalId;
    }

    function checkVoted(uint voteId, address addr) public view returns (bool) {
        if(voteId > lastDirectorVoteId)
            return false;
        DirectorVote storage dv = directorVotes[voteId];
        uint len = dv.alreadyVoted.length;
        if (0 == len)
            return false;
        for(uint i = 0; i < len; i++) {
            if (addr == dv.alreadyVoted[i])
                return true;
        }
        return false;
    }

    function directorVote(uint voteId, VoteAttitude attitude) public auth("DIRECTOR") {
        require(voteId <= lastDirectorVoteId, "vote not exist");
        DirectorVote storage dv = directorVotes[voteId];
        updateDirectorVoteStatus(voteId);
        require(VoteStatus.ONGOING == dv.status, "vote not ongoing");
        require(!checkVoted(voteId,msg.sender),"already voted");
        require(VoteAttitude.ABSTAIN != attitude);
        if (VoteAttitude.AGREE == attitude) {
            dv.agreeVotes = add(dv.agreeVotes, 1);
        } else {
            dv.disagreeVotes = add(dv.disagreeVotes,1);
        }
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
        require(directorVotes[prps.directorVoteId].agreeVotes >= directorVotes[prps.directorVoteId].passVotes);
        // if(prps.pisVoteId != 0) {
        //     updatePISVoteStatus(prps.pisVoteId);
        //     require(VoteStatus.APPROVED == pisVotes[prps.pisVoteId].status);
        // }
        if(false == prps.executed) {
            execute(prps.target,abi.encodePacked(prps.func, prps.param));
            prps.executed = true;
        }
    }

    function advancePISVote(uint proposalId) public {
        require(proposalId <= lastAssignedProposalId, "proposal not exist");
        Proposal storage prps = voteProposals[proposalId];
        require(directorVotes[prps.directorVoteId].agreeVotes >= directorVotes[prps.directorVoteId].passVotes);
        if(prps.pisVoteId != 0) {
           pisVotes[prps.pisVoteId].startTime = height();
        }
    }

    function height() public view returns (uint256) {
        return block.number;
    }
}