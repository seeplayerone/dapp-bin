pragma solidity 0.4.25;

import "./template.sol";
import "./acl.sol";

// 预编译合约接口
interface Instructions{
    function createAsset(uint32 indivisible, uint32 coinId, uint256 amount) external;
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
    string orgName;
    Instructions instructions;
    Registry registry;
    string constant ROLE_MANAGER = "ROLE_MANAGER";
    
    bool initialized;

    function initialize() public {
        initialized = true;
    }

    modifier hasInitialized() {
        require(initialized);
        _;
    }
    constructor(string _orgName) public {
        orgName = _orgName;
        instructions =  Instructions(0x7E40Cbb99Aa080F2B3394D28D409b5391F8dE9EA);
        registry = Registry(0x66f84b824Efa449F5f9E5d5fC70F81C232c2EFE4);
        
        // init admin role
        configureAddressRoleInternal(msg.sender, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ROLE, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADDRESS_ROLE, ROLE_MANAGER, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_FUNCTION_ADDRESS, ROLE_MANAGER, OpMode.Add);
    }
    
    function register() internal {
        registry.orgRegistry(orgName, templateName);
    }
    
    function create(uint32 indivisible, uint32 coinId, uint256 amount) internal {
        instructions.createAsset(indivisible, coinId, amount);
    }
    
    function mint(uint32 coinId, uint256 amount) internal {
        instructions.mintAsset(coinId, amount);
    }
    
    function transfer(address to, uint32 assetType, uint32 orgId, uint32 coinId, uint256 amount) internal {
        instructions.transfer(to, assetType, orgId, coinId, amount);
    }
}
