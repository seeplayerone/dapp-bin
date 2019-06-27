pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/string_utils.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";

//import "./string_utils.sol";
//import "./template.sol";

/// @dev ACL interface
///  ACL is provided by Flow Kernel
interface ACL {
    function canPerform(address _caller, string _functionHash) external view returns (bool);
}

/// @title This is a simple vote contract
///  every voter is equal and represents the same voting weight
/// @dev Note every contract to deploy and run on Flow must directly or indirectly inherits Template
contract SimpleVote is Template {
    using StringLib for string;
    
    uint lastAssignedVoteId = 0;
    
    /// vote status enumeration
    enum VoteStatus {ONGOING, APPROVED, REJECTED}
    
    /// functionHash - ACL through the organization contract
    string constant START_VOTE_FUNCTION = "START_VOTE_FUNCTION";
    string constant VOTE_FUNCTION = "VOTE_FUNCTION";
    
    struct Vote {
        /// vote subject
        string subject;
        /// vote proposer
        address proposer;
        /// vote type (approved by all 1, approved by certain percentage 2)
        uint voteType;
        /// total number of vote participants
        uint totalParticipants;
        /// the vote successful percentage when vote type is 2
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
    }
   
    /// all votes in this contract
    mapping(uint => Vote) votes;
    
    /// ACL interface reference
    ACL acl;
    
    /// organization contract
    address organizationContract;
 
    /*constructor(address _organizationContract) public {
        organizationContract = _organizationContract;
        acl = ACL(_organizationContract);
    }*/
    
    function setOrganization(address _organizationContract) public {
        organizationContract = _organizationContract;
        acl = ACL(_organizationContract);
    }

    function getOrganization() public view returns (address){
        return organizationContract;
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
    /// @param totalParticipants total participant number
    /// @param percent successful percentage of vote type 2
    /// @param endTime vote end time
    /// @param func functionHash of callback method
    /// @param param parameters for callback method
    function startVote(string subject, uint voteType, uint totalParticipants, uint percent, uint endTime, bytes4 func, bytes param)
        public 
    //    authFunctionHash(START_VOTE_FUNCTION)
        returns(uint)
    {
        require(voteType == 1 || voteType == 2, "unsupported vote type");
        if (1 == voteType) {
            require(totalParticipants >= 1 && 100 == percent);
        }
        if (2 == voteType) {
            require(percent >= 1 && percent <= 99);
        }
        require(endTime > block.timestamp, "invalid vote end time");
        
        /// @dev jack code review: why doing in this way
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
    
        //delete votes[0];
        lastAssignedVoteId++;
    
        return voteId;
    }

    function getVoteInfo(uint voteId) public view returns (string) {
        Vote storage va = votes[voteId];
        if(va.exist) {
            return (va.subject);
        }
        return ("no such vote");
    }

    function getLastVoteId() public view returns (uint) {
        return lastAssignedVoteId;
    }

    /// @dev participate in a vote
    /// @param voteId vote id
    /// @param attitude vote for yes/no
    function vote(uint voteId, bool attitude) public 
    //    authFunctionHash(VOTE_FUNCTION) 
    {
        Vote storage va = votes[voteId];
        require(va.exist && VoteStatus.ONGOING == va.status, "vote not existed or not ongoing");
        // require(block.timestamp >= va.startTime && block.timestamp <= va.endTime, "not valid voting time");
        
        address voter = msg.sender;
        /// type 1
        if (1 == va.voteType) {
            if (attitude) {
                va.approvers.push(voter);
                if (va.approvers.length == va.totalParticipants) {
                    va.status = VoteStatus.APPROVED;

                    invokeOrganizationContract(va.func, va.param);
                }
            } else {
                va.rejecters.push(voter);
                va.status = VoteStatus.REJECTED;
            }
        }
        /// type 2
        else if (2 == va.voteType) {
            if (attitude) {
                va.approvers.push(voter);
                if (va.approvers.length*100/va.totalParticipants >= va.percent) {
                    va.status = VoteStatus.APPROVED;

                    invokeOrganizationContract(va.func, va.param);
                }
            } else {
                va.rejecters.push(voter);
                if (va.rejecters.length*100/va.totalParticipants > (100-va.percent)) {
                    va.status = VoteStatus.REJECTED;
                }
            }
        }
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




