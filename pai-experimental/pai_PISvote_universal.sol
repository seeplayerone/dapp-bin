pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

// import "./3rd/math.sol";
// import "./string_utils.sol";
// import "./template.sol";
// import "./pai_main.sol";


/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteUniversal is Template, DSMath {
    using StringLib for string;
    
    /// params to be init
    PAIDAO paiDAO;
    uint96 voteAssetGlobalId;
    uint lastAssignedVoteId = 0;
 
    /// vote param
    enum VoteStatus {ONGOING, APPROVED, REJECTED}
    uint passPercentage = RAY / 2;
    uint startPercentage = RAY / 1000;

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);
    
    struct Vote {
        /// vote subject
        string subject;
        /// vote proposer
        address proposer;
        /// voted for approval
        uint agreeVotes;
        /// addresses voted for reject
        uint disagreeVotes;
        /// vote start time, measured by block timestamp
        uint startTime;
        /// vote duration
        uint duration;
        /// vote status
        VoteStatus status;
        /// call contract
        address target;
        /// functionHash of the callback function
        bytes4 func;
        /// parameters for the callback function
        bytes param;     
    }
   
    /// all votes in this contract
    mapping(uint => Vote) votes;
    
    function setOrganization(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        voteAssetGlobalId = paiDAO.getPISGlobalId();
    }

    /// get the organization contract address
    function getOrganization() public view returns (address) {
        return paiDAO;
    }

    function getVoteAssetGlobalId() public view returns (uint) {
        return voteAssetGlobalId;
    }

    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(paiDAO.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this),func)));
        _;
    }
 
    /// @dev start a vote
    /// @param _subject vote subject
    /// @param _duration vote end time
    /// @param _func functionHash of callback method
    /// @param _param parameters for callback method
    function startVote(string _subject, uint _duration, address _targetContract, bytes4 _func, bytes _param) public payable {
        //require(endTime > block.timestamp, "invalid vote end time");
        
        Vote memory va;
        va.subject = _subject;
        va.proposer = msg.sender;
        va.agreeVotes = 0;////need add startVote number
        va.disagreeVotes = 0;
        va.startTime = block.timestamp;
        va.duration = _duration;
        va.status = VoteStatus.ONGOING;
        va.target = _targetContract;
        va.func = _func;
        va.param = _param;
        
        votes[lastAssignedVoteId] = va;
        emit CreateVote(lastAssignedVoteId);
        lastAssignedVoteId = add(lastAssignedVoteId,1);
    }

    /// @dev get basic information of a vote
    function getVoteInfo(uint voteId) public view returns (string, address, uint, uint, uint, VoteStatus) {
        Vote storage va = votes[voteId];
        if(voteId <= lastAssignedVoteId) {
            return (va.subject, va.proposer, va.agreeVotes, va.disagreeVotes, passPercentage, va.status);
        }
        return ("no such vote", 0x0, 0, 0, 0, VoteStatus.REJECTED);
    }

    /// @dev get last vote id
    function getLastVoteId() public view returns (uint) {
        return lastAssignedVoteId;
    }

    /// @dev participate in a vote
    /// @param voteId vote id
    /// @param attitude vote for yes/no
    function vote(uint voteId, bool attitude) public {
        require(voteId <= lastAssignedVoteId, "vote not exist");
        Vote storage va = votes[voteId];
        
        //require(va.exist && VoteStatus.ONGOING == va.status, "vote not exist or not ongoing");
        //require(block.timestamp >= va.startTime && block.timestamp <= va.endTime, "not valid vote time");
        
        //address voter = msg.sender;
        // require(!va.votersMap[voter], "already voted");

        // va.votersMap[voter] = true;

        if (attitude) {
            va.agreeVotes = va.agreeVotes + 100;
            if (va.agreeVotes >= 300) {
                va.status = VoteStatus.APPROVED;
                invokeOrganizationContract(va.func, va.param);
            }
        } else {
            va.disagreeVotes = va.disagreeVotes + 100;
            if (va.disagreeVotes >= 300) {
                va.status = VoteStatus.REJECTED;
            }
        }
        emit ConductVote(va.agreeVotes, va.disagreeVotes, va.status);
    }

    /// @dev callback function to invoke organization contract   
    /// @param _func functionHash
    /// @param _param bytecode parameter
    function invokeOrganizationContract(bytes4 _func, bytes _param) internal {
        address tempAddress = paiDAO;
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




