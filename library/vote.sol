pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";

// import "../pai-experimental/3rd/math.sol";   ///never tested
// import "./template.sol";                     ///never tested


/// @title This is a vote base contract, so it is not necessary to check permissions
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract BasicVote is Template, DSMath {
    using StringLib for string;

    enum VoteStatus {ONGOING, APPROVED, REJECTED}
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
        require(_endTime > block.timestamp, "invalid vote end time");
        require(_totalVotes > 0, "totalVotes should greater than zero");
        require(_totalVotes >= _throughVotes, "_throughVotes should greater than or equal to totalVotes");

        Vote memory va;
        va.subject = _subject;
        va.proposer = msg.sender;
        va.agreeVotes = 0;
        va.disagreeVotes = 0;
        va.throughVotes = _throughVotes;
        va.totalVotes = _totalVotes;
        va.startTime = startTime;
        va.endTime = endTime;
        va.status = VoteStatus.ONGOING;
        va.target = _targetContract;
        va.func = _func;
        va.param = _param;
        va.executed = false;

        lastAssignedVoteId = add(lastAssignedVoteId,1);
        votes[lastAssignedVoteId] = va;
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
            return ("no such vote", 0x0, 0, 0, 0, VoteStatus.REJECTED,0x0,"","",false);
    }

    /// @dev get last vote id
    function getLastVoteId() public view returns (uint) {
        return lastAssignedVoteId;
    }

    function updateVoteStatus(uint voteId) internal {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        Vote storage va = votes[voteId];
        if (VoteStatus.ONGOING == va.status) {
            if (block.timestamp > va.endTime) {
                va.status = VoteStatus.REJECTED;
            } else if (va.agreeVotes >= va.throughVotes) {
                va.status = VoteStatus.APPROVED;
            } else if (va.disagreeVotes > sub(va.totalVotes,va.throughVotes)) {
                va.status = VoteStatus.REJECTED;
            }
        }
    }

    /// @dev participate in a vote
    /// @param voteId vote id
    /// @param attitude vote for yes/no
    /// @param voteNumber number of votes that voter willing to vote
    function voteInternal(uint voteId, bool attitude, uint voteNumber) internal {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        Vote storage va = votes[voteId];
        require(VoteStatus.ONGOING == va.status, "vote not ongoing");
        require(block.timestamp >= va.startTime, "vote not open");
        require(block.timestamp <= va.endTime, "vote closed");
        require(voteNumber > 0, "number of vote should be greater than zero");
        //require(block.timestamp >= va.startTime, "vote not open"); ///still need?

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
        updateVoteStatus(voteId);
        Vote storage va = votes[voteId];
        if(VoteStatus.APPROVED == va.status && false == va.executed) {
            invokeOrganizationContract(va.func, va.param, va.target);
            va.executed = true;
        }
    }

    /// @dev callback function to invoke organization contract   
    /// @param _func functionHash
    /// @param _param bytecode parameter
    function invokeOrganizationContract(bytes4 _func, bytes _param, address _addr) internal {
        address tempAddress = _addr;
        uint paramLength = _param.length;
        uint totalLength = 4 + paramLength;

        assembly {
            let p := mload(0x40)
            mstore(p, _func)
            for { let i := 0 } lt(i, paramLength) { i := add(i, 32) } {
                mstore(add(p, add(4,i)), mload(add(add(_param, 0x20), i)))
            }
            
            let success := call(not(0), tempAddress, 0, 0, p, totalLength, 0, 0)

            let size := returndatasize
            returndatacopy(p, 0, size)

            switch success
            case 0 {
                revert(p, size)
            }
            default {
                return(p, size)
            }
        }
    } 
}




