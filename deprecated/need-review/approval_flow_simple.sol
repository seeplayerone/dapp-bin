pragma solidity 0.4.25;

import "./string_utils.sol";
import "./template.sol";

/// @dev ACL interface
///  ACL is provided by Flow Kernel
interface ACL {
    function canPerform(address _caller, string _function) external view returns (bool);
    function getAddressRolesMap(address _address) external view returns (bytes32[]);
}

/// @title This is a simple approval flow smart contract
///  an approval flow consists of multiple steps, it goes to step N+1 once step N is approved
///  in every step, we can configure authorized addresses or roles
/// @dev Note every contract to deploy and run on Flow must directly or indirectly inherits Template
contract SimpleApprovalFlow is Template {
    using StringLib for string;
    
    uint lastAssignedId = 0;
    
    /// approval status enuermations
    enum ApprovalStatus {APPROVING, attitude, REJECTED}
    
    /// functionHash strings
    string constant START_APPROVAL_FLOW_FUNCTION = "START_APPROVAL_FLOW_FUNCTION";
    string constant APPROVE_FUNCTION = "APPROVE_FUNCTION";

    /// splitter flag to seperate roles for each flow step in the array
    bytes32 constant ROLE_FLAG = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    /// struct to keep an approval flow 
    struct ApprovalFlow {
        /// approval subject
        string subject;
        /// approval steps
        ApprovalStep[] approvals;
        /// the current step
        uint currentStep;
        /// approval start time
        uint startTime;
        /// approval end time
        uint endTime;
        /// approval status
        ApprovalStatus status;
        /// whether the approval flow exists
        bool exist;
        /// functionHash of the callback function
        bytes4 func;
        /// parameters for the callback function
        bytes param;
    }
    
    /// struct to keep one step in an approval flow
    struct ApprovalStep {
        /// allowed roles
        bytes32[] approverRoles;
        /// the approver
        address approver;
        /// the approving time
        uint approveTime;
    }
    
    /// all approval flows in this contract
    mapping(uint => ApprovalFlow) flows;
    
    /// ACL interface reference
    ACL acl;
    
    /// organization contract
    address organizationContract;
    
    constructor(address _organizationContract) public {
        organizationContract = _organizationContract;
        acl = ACL(_organizationContract);
    }
    
    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple approval flow contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(acl.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this), func)));
        _;
    }
    
    /// @dev start an approval flow
    /// @param subject the approval subject
    /// @param totalSteps total steps in the approval flow
    /// @param endTime end time
    /// @param roles roles for each step, seperated by ROLE_FLAG
    /// @param func functionHash of callback method
    /// @param param parameters for callback method
    function startApprovalFlow(string subject, uint totalSteps, uint endTime, bytes32[] roles, bytes4 func, bytes param)
        public 
        authFunctionHash(START_APPROVAL_FLOW_FUNCTION)
        returns(uint) 
    {
        require(totalSteps >= 1, "invalid step number");
        require(endTime > block.timestamp, "invalid vote end time");
        require(roles.length > 0);
        
        ApprovalFlow storage af = flows[0];
        af.subject = subject;
        af.approvals.length = totalSteps;
        /// parse roles for each step from the roles array
        /// Note this is a workaround as it is not possible to pass in a 2 dimensional array in Solidity
        uint roleIndex = 0;
        for (uint m = 1; m <= totalSteps; m++) {
            ApprovalStep storage a = af.approvals[m-1];
            for (uint k = roleIndex; k < roles.length; k++) {
                roleIndex++;
                if (roles[k] != ROLE_FLAG) {
                    a.approverRoles.push(roles[k]);
                } else {
                    break;
                }
            }
        }
        require(totalSteps == af.approvals.length, "totalSteps does not match roles length");
        
        af.currentStep = 1;
        af.startTime = block.timestamp;
        af.endTime = endTime;
        af.status = ApprovalStatus.APPROVING;
        af.exist = true;
        af.func = func;
        af.param = param;
        uint approvalId = lastAssignedId+1;
        flows[approvalId] = af;

        delete flows[0];
        lastAssignedId++;
        
        return approvalId;
    }
    
    /// @dev approve
    /// @param id the approval flow id
    /// @param attitude approve or not
    /// @dev whether we should use the authFunctionHash() at the function level or call canPerform() seperately inside it???
    function approve(uint id, bool attitude) public authFunctionHash(APPROVE_FUNCTION) {
        ApprovalFlow storage af = flows[id];
        require(af.exist && ApprovalStatus.APPROVING == af.status, "no such approval flow");
        
        uint currentStep = af.currentStep;
        ApprovalStep storage a = af.approvals[currentStep-1];
        
        bool isApprover;
        bytes32[] storage roles = a.approverRoles;
        bytes32[] memory hasRoles = acl.getAddressRolesMap(msg.sender);
        if (hasRoles.length > 0) {
            for (uint j = 0; j < roles.length; j++) {
                for (uint n = 0; n < hasRoles.length; n++) {
                    if (roles[j] == hasRoles[n]) {
                        isApprover = true;
                        break;
                    } 
                }
            }
        }
        require(isApprover, "not authorized");
        
        if (attitude) {
            if (af.approvals.length == currentStep) {
                af.status = ApprovalStatus.attitude;
                
                invokeOrganizationContract(af.func, af.param);
            } else {
                af.currentStep++;
            }
        } else {
            af.status = ApprovalStatus.REJECTED;
        }
        a.approver = msg.sender;
        a.approveTime = block.timestamp;
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
            
            let success := call(not(0), tempAddress, 0, p, totalLength, 0, 0)

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



