pragma solidity 0.4.25;

import "./template.sol";
import "./acl.sol";

/// @dev the Instructions interface
///  Instructions is a system contract
interface Instructions{
    function createAsset(uint32 assetType, uint32 assetIndex, uint256 amount) external;
    function mintAsset (uint32 assetIndex, uint256 amount) external;
    function transfer(address to, uint32 assetType, uint32 organizationId ,uint32 assetIndex, uint256 amount) external;
}

/// @dev the Registry interface
///  Registry is a system contract
interface Registry {
     function registerOrganization(string organizationName, string templateName) external;
     function hasRegistered() external returns (bool);
}

/// @title Simple organization which inherits Template, it has capabilities to:
///  - register to Registry and create/mint assets on Flow chain
///  - provide basic permission management through ACL contract
contract Organization is Template, ACL{
    string organizationName;
    Instructions instructions;
    Registry registry;
    string constant ROLE_MANAGER = "ROLE_MANAGER";
    
    /// @dev initialization function module to support complex business requirements during organization startup
    ///  which contains an initialized state, an initialize() function and a hasInitialized() modifier
    bool initialized;

    function initialize() public {
        initialized = true;
    }

    modifier hasInitialized() {
        require(initialized);
        _;
    }

    /// @dev constructor
    /// @param _organizationName organization name
    constructor(string _organizationName) public {
        organizationName = _organizationName;
        instructions =  Instructions(0x79A961d796afAa37e53c40Aba0eF621Be999697b);
        registry = Registry(0xe9d72E727972BE60f0b8554a39438f7a35e225ae);
        
        /// default permission management settings, which grants the contract creator the "super admin" role
        configureAddressRoleInternal(msg.sender, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ROLE, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADDRESS_ROLE, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ADDRESS, ROLE_MANAGER, OpMode.Add);
    }
    
    /// @dev register to Registry Center
    function register() internal {
        registry.registerOrganization(organizationName, templateName);
    }
    
    /// @dev create an asset
    /// @param assetType divisible 0, indivisible 1
    /// @param assetIndex asset index in the organization
    /// @param amount amount of asset to create (or the unique voucher id for an indivisible asset)
    function create(uint32 assetType, uint32 assetIndex, uint256 amount) internal {
        instructions.createAsset(assetType, assetIndex, amount);
    }

    /// @dev mint an asset
    /// @param assetIndex asset index in the organization
    /// @param amount amount of asset to mint (or the unique voucher id for an indivisible asset)    
    function mint(uint32 assetIndex, uint256 amount) internal {
        instructions.mintAsset(assetIndex, amount);
    }
    
    /// @dev transfer an asset
    /// @param to the destination address
    /// @param assetType divisible 0, indivisible 1
    /// @param organizationId organization id
    /// @param assetIndex asset index in the organization
    /// @param amount amount of asset to transfer (or the unique voucher id for an indivisible asset)    
    function transfer(address to, uint32 assetType, uint32 organizationId, uint32 assetIndex, uint256 amount) internal {
        instructions.transfer(to, assetType, organizationId, assetIndex, amount);
    }
}
