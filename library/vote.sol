pragma solidity 0.4.25;

<<<<<<< HEAD
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
=======
import "../pai-experimental/3rd/math.sol";
import "./execution.sol";
>>>>>>> 1fe0cfad4b8a655a254e6309fc30278620be3937

/// @title This is a vote base contract, so it is not necessary to check permissions
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract BasicVote is DSMath, Execution {

    enum VoteStatus {NOTSTARTED, ONGOING, APPROVED, REJECTED}
    uint lastAssignedVoteId = 0;

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);

    struct Vote {
        string subject;
        address proposer;
        uint agreeVotes;
        uint disagreeVotes;
        uint throughVotes;
        uint totalVotes;
        uint startTime; /// vote start time, measured by block timestamp
        uint endTime;  /// vote end time, measured by block timestamp
        VoteStatus status;
        address target; /// call contract of vote result
        bytes4 func; /// functionHash of the callback function
        bytes param; /// parameters for the callback function
        bool executed; /// whether vote result is executed
    }
   
    /// all votes in this contract
    mapping(uint => Vote) votes;

    /// @dev start a vote
    function startVoteInternal(
         string _subject,
           uint _throughVotes,
           uint _totalVotes,
           uint _startTime,
           uint _endTime,
        address _targetContract,
         bytes4 _func,
          bytes _param
        )
        internal
        returns(uint)
    {
        require(_endTime > _startTime, "endTime should be later than startTime");
        require(_endTime > timeNow(), "invalid vote end time");
        require(_totalVotes > 0, "totalVotes should greater than zero");
        require(_totalVotes >= _throughVotes, "_throughVotes should greater than or equal to totalVotes");

        Vote memory va;
        va.subject = _subject;
        va.proposer = msg.sender;
        va.agreeVotes = 0;
        va.disagreeVotes = 0;
        va.throughVotes = _throughVotes;
        va.totalVotes = _totalVotes;
        va.startTime = _startTime;
        va.endTime = _endTime;
        va.target = _targetContract;
        va.func = _func;
        va.param = _param;
        va.executed = false;

        lastAssignedVoteId = add(lastAssignedVoteId,1);
        votes[lastAssignedVoteId] = va;
        updateVoteStatus(lastAssignedVoteId);
        emit CreateVote(lastAssignedVoteId);
        return lastAssignedVoteId;
    }

    /// @dev get basic information of a vote
    function getVoteInfo(uint voteId) public view returns (
        string, address, uint, uint, uint, VoteStatus, address, string, string, bool) {  //maybe need more information?
            Vote storage va = votes[voteId];
            if(voteId <= lastAssignedVoteId) {
                //the following coding should be moved to some libaray
                bytes memory _func = new bytes(4);
                for(uint i = 0; i < 4; i++) {
                    _func[i] = va.func[i];
                }
                //the above coding should be moved to some libaray

                return (
                    va.subject,
                    va.proposer,
                    mul(va.agreeVotes, RAY) / va.totalVotes, /// Pro-proportionality
                    mul(va.disagreeVotes, RAY) / va.totalVotes, /// Anti-proportionality
                    mul(va.throughVotes, RAY) / va.totalVotes, /// required proportion
                    va.status,
                    va.target,
                    string(_func),
                    string(va.param),
                    va.executed
                    );
            }
            return ("no such vote", 0x0, 0, 0, 0, VoteStatus.REJECTED, 0x0, "", "", false);
    }

     function getVoteStatus(uint voteId) public view returns (VoteStatus) {
            Vote storage va = votes[voteId];
            if(voteId <= lastAssignedVoteId) {
                return va.status;
            }
            return VoteStatus.REJECTED;
    }

    /// @dev get last vote id
    function getLastVoteId() public view returns (uint) {
        return lastAssignedVoteId;
    }

    function getVoteEndTime(uint voteId) public returns (uint) {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        updateVoteStatus(voteId);
        Vote storage va = votes[voteId];
        if(va.status != VoteStatus.ONGOING) {
            return 0;
        } else {
            return va.endTime;
        }
    }

    function updateVoteStatus(uint voteId) public {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        Vote storage va = votes[voteId];
        if (timeNow() < va.startTime) {
            va.status = VoteStatus.NOTSTARTED;
        } else if (timeNow() > va.endTime) {
            if(VoteStatus.ONGOING == va.status) {
                va.status = VoteStatus.REJECTED;
            }
        } else if (va.agreeVotes >= va.throughVotes) {
            va.status = VoteStatus.APPROVED;
        } else if (va.disagreeVotes > sub(va.totalVotes,va.throughVotes)) {
            va.status = VoteStatus.REJECTED;
        } else {
            va.status = VoteStatus.ONGOING;
        }
    }

    /// @dev participate in a vote
    /// @param voteId vote id
    /// @param attitude vote for yes/no
    /// @param voteNumber number of votes that voter willing to vote
    function voteInternal(uint voteId, bool attitude, uint voteNumber) internal {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        updateVoteStatus(voteId);
        Vote storage va = votes[voteId];
        require(VoteStatus.ONGOING == va.status, "vote not ongoing");
        require(voteNumber > 0, "number of vote should be greater than zero");

        if (attitude) {
            va.agreeVotes = add(va.agreeVotes, voteNumber);
        } else {
            va.disagreeVotes = add(va.disagreeVotes,voteNumber);
        }
        updateVoteStatus(voteId);
        emit ConductVote(mul(va.agreeVotes, RAY) / va.totalVotes, mul(va.disagreeVotes, RAY) / va.totalVotes, va.status);
    }

    /// @dev callback function to invoke organization contract
    function invokeVoteResult(uint voteId) public {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        Vote storage va = votes[voteId];
        if(VoteStatus.APPROVED == va.status && false == va.executed) {
            execute(va.target,abi.encodePacked(va.func, va.param));
            va.executed = true;
        }
    }

    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
}




