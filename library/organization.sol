pragma solidity 0.4.25;

import "./template.sol";
import "./acl.sol";

/// @dev the Instructions interface
///  Instructions is a system contract
interface Instructions{
    function createAsset(uint32 assetType, uint32 assetIndex, uint256 amount) external;
    function mintAsset (uint32 assetIndex, uint256 amount) external;
    function transfer(address to, bytes12 asset, uint256 amount) external;
    function asset() external returns (bytes12);
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
    string internal organizationName;
    Instructions internal instructions;
    Registry internal registry;
    
    /// @dev initialization function module to support complex business requirements during organization startup
    ///  which contains an initialized state, an initialize() function and a hasInitialized() modifier
    bool internal initialized;

    function initialize() public {
        initialized = true;
    }

    modifier hasInitialized() {
        require(initialized);
        _;
    }

    string constant SUPER_ADMIN = "SUPER_ADMIN";
    /// @dev constructor
    /// @param _organizationName organization name
    constructor(string _organizationName) public {
        organizationName = _organizationName;
        instructions =  Instructions(0x635b2ab517b8cb9a1017421a726d081aea01d19376);
        registry = Registry(0x6364552cbabde79285cc483640d516764f2fb105bd);
        
        /// default permission management settings, which grants the contract creator the "super admin" role
        configureAddressRoleInternal(msg.sender, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_NORMAL_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADVANCED_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_SUPER_FUNCTION, SUPER_ADMIN, OpMode.Add);
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
    /// @param asset combined of assetType（divisible 0, indivisible 1）、
    ///     organizationId（organization id）、
    ///     assetIndex（asset index in the organization）
    /// @param amount amount of asset to transfer (or the unique voucher id for an indivisible asset)    
    function transfer(address to, bytes12 asset, uint256 amount) internal {
        instructions.transfer(to, asset, amount);
    }
    
    /// @dev get the asset id from the transaction
    function getAsset() internal returns(bytes12) {
        return instructions.asset();
    }
}
