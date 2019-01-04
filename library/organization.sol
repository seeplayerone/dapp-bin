pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/acl.sol";

// 预编译合约接口
interface Instructions{
    function createAsset(bool indivisible, uint32 coinId, uint256 amount) external;
    function mintAsset (uint32 coinId, uint256 amount) external;
    function transfer(address to, uint32 assetType, uint32 orgId ,uint32 coinId, uint256 amount) external;
}

// 注册中心接口
interface Registry {
     function orgRegistry(string orgName, string templateName) external;
     function getOrgId() external;
     function registered() external returns (bool);
}

contract Organization is Template, ACL{
    string public orgName;
    Instructions instructions;
    Registry registry;
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    bool initialized;

    function initialize() public {
        initialized = true;
    }

    modifier hasInitialized() {
        require(initialized);
        _;
    }
    constructor(uint16 _category, string _parent, string _orgName, address _precompileAddr, address _registryAddr) Template(_category, _parent) public {
        category = _category; 
        parent = _parent;
        orgName = _orgName;
        instructions =  Instructions(_precompileAddr);
        registry = Registry(_registryAddr);
        
        // init admin role
        configureAddressRoleInternal(msg.sender, ADMIN_ROLE, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ROLE, ADMIN_ROLE, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADDRESS_ROLE, ADMIN_ROLE, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ADDRESS, ADMIN_ROLE, OpMode.Add);
    }
    
    bytes32 constant REGISTER_FUNCTION = keccak256("REGISTER_FUNCTION");
    function register() internal {
        registry.orgRegistry(orgName, parent);
    }
    
    bytes32 constant CREATE_ASSET_FUNCTION = keccak256("CREATE_ASSET_FUNCTION");
    function create(bool indivisible, uint32 coinId, uint256 amount) internal {
        instructions.createAsset(indivisible, coinId, amount);
    }
    
    bytes32 constant MINT_ASSET_FUNCTION = keccak256("MINT_ASSET_FUNCTION");
    function mint(uint32 coinId, uint256 amount) internal {
        instructions.mintAsset(coinId, amount);
    }
    
    bytes32 constant TRANSFER_ASSET_FUNCTION = keccak256("TRANSFER_ASSET_FUNCTION");
    function transfer(address to, uint32 assetType, uint32 orgId, uint32 coinId, uint256 amount) internal {
        instructions.transfer(to, assetType, orgId, coinId, amount);
    }
}
