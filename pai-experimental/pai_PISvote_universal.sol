pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

// import "./3rd/math.sol";
// import "./string_utils.sol";
// import "./template.sol";
// import "./pai_main.sol";

/// @dev ACL interface
///  ACL is provided by the organization contract
interface ACL {
    function canPerform(address _caller, string _functionHash) external view returns (bool);
}

/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteUniversal is Template,DSMath {
    using StringLib for string;
    
    /// params to be init
    ACL acl;
    address organizationContract;
    uint96 voteAssetGlobalId;
    uint lastAssignedVoteId = 0;
 
    /// vote status enumeration
    enum VoteStatus {ONGOING, APPROVED, REJECTED}

    // vote event
    event CreateVote(uint);
    event ConductVote(uint, uint, VoteStatus);
    
    struct Vote {
        /// vote subject
        string subject;
        /// vote proposer
        address proposer;
        /// vote type (approved by all - 1, approved by a certain percentage - 2)
        uint voteType;
        /// total number of vote participants
        uint totalParticipants;
        /// required percentage (in RAY )
        uint percent;
        /// addresses voted for approval
        address[] approvers;
        /// addresses voted for reject
        address[] rejecters;
        /// vote start time, measured by block timestamp
        uint startTime;
        /// vote end time, measured by block timestamp
        uint endTime;
        /// vote status
        VoteStatus status;
        /// whether the vote exists
        bool exist;
        /// functionHash of the callback function
        bytes4 func;
        /// parameters for the callback function
        bytes param;

        mapping(address => bool) votersMap;        
    }
   
    /// all votes in this contract
    mapping(uint => Vote) votes;
    

 
    function setOrganization(address _organizationContract) public {
        organizationContract = _organizationContract;
        acl = ACL(_organizationContract);
        (,voteAssetGlobalId) = organizationContract.getAdditionalAssetInfo(0);
    }

    /// get the organization contract address
    function getOrganization() public view returns (address){
        return organizationContract;
    }

    function getVoteAssetGlobalId() public view returns (uint){
        return voteAssetGlobalId;
    }

    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(acl.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this),func)));
        _;
    }
 
    /// @dev start a vote
    /// @param subject vote subject
    /// @param voteType vote type
    /// @param totalParticipants total participants
    /// @param percent required participants
    /// @param endTime vote end time
    /// @param func functionHash of callback method
    /// @param param parameters for callback method
    function startVote(string subject, uint voteType, uint totalParticipants, uint percent, uint endTime, bytes4 func, bytes param)
        public 
        authFunctionHash(START_VOTE_FUNCTION)
        returns(uint)
    {
        require(voteType == 1 || voteType == 2, "unsupported vote type");
        if (1 == voteType) {
            require(totalParticipants >= 1);
        }
        if (2 == voteType) {
            require(percent >= 1 && percent <= 100);
        }
        require(endTime > block.timestamp, "invalid vote end time");
        
        Vote memory va;
        va.subject = subject;
        va.proposer = msg.sender;
        va.voteType = voteType;
        va.totalParticipants = totalParticipants;
        va.percent = percent;
        va.approvers = new address[](0);
        va.rejecters = new address[](0);
        va.startTime = block.timestamp;
        va.endTime = endTime;
        va.status = VoteStatus.ONGOING;
        va.exist = true;
        va.func = func;
        va.param = param;
        
        uint voteId = lastAssignedVoteId + 1;
        votes[voteId] = va;
    
        lastAssignedVoteId++;

        emit CreateVote(voteId);
    
        return voteId;
    }

    /// @dev get basic information of a vote
    function getVoteInfo(uint voteId) public view returns (string, address, uint, uint, uint, VoteStatus) {
        Vote storage va = votes[voteId];
        if(va.exist) {
            return (va.subject, va.proposer, va.approvers.length, va.rejecters.length, va.percent, va.status);
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
    function vote(uint voteId, bool attitude) public 
        authFunctionHash(VOTE_FUNCTION) 
    {
        Vote storage va = votes[voteId];
        require(va.exist && VoteStatus.ONGOING == va.status, "vote not exist or not ongoing");
        require(block.timestamp >= va.startTime && block.timestamp <= va.endTime, "not valid vote time");
        
        address voter = msg.sender;
        require(!va.votersMap[voter], "already voted");

        va.votersMap[voter] = true;
        /// type 1
        if (1 == va.voteType) {
            if (attitude) {
                va.approvers.push(voter);
                if (va.approvers.length == va.totalParticipants) {
                    va.status = VoteStatus.APPROVED;
                    emit ConductVote(va.approvers.length, va.rejecters.length, va.status);
                    invokeOrganizationContract(va.func, va.param);
                }
            } else {
                va.rejecters.push(voter);
                va.status = VoteStatus.REJECTED;
                /// emit ConductVote(va.approvers.length, va.rejecters.length, va.status);
            }
        }
        /// type 2
        else if (2 == va.voteType) {
            if (attitude) {
                va.approvers.push(voter);
                if (va.approvers.length*100 >= va.percent*va.totalParticipants) {
                    va.status = VoteStatus.APPROVED;
                    emit ConductVote(va.approvers.length, va.rejecters.length, va.status);
                    invokeOrganizationContract(va.func, va.param);
                }
            } else {
                va.rejecters.push(voter);
                if (va.rejecters.length*100 > (100-va.percent)*va.totalParticipants) {
                    va.status = VoteStatus.REJECTED;
                }
                /// emit ConductVote(va.approvers.length, va.rejecters.length, va.status);
            }
        }

        emit ConductVote(va.approvers.length, va.rejecters.length, va.status);
    }

    /// @dev callback function to invoke organization contract   
    /// @param _func functionHash
    /// @param _param bytecode parameter
    function invokeOrganizationContract(bytes4 _func, bytes _param) internal {
        address tempAddress = organizationContract;
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




