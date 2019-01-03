pragma solidity ^0.4.25;

contract ACL {
    // 配置权限的操作类型
    enum OpMode { Add, Remove }
    
    // 权限值结构体
    struct Roles {
        bool exist;
        bytes32[] value; 
    }
    
    // 地址值结构体
    struct Addresses {
        bool exist;
        address[] value;
    }
    
    // functionHash -> roleHash：映射方法对应的角色
    mapping (bytes32 => Roles) functionRoles; 
    // address -> roleHash：映射地址对应的角色
    mapping (address => Roles) addressRoles;
    // functionHash -> address：映射方法有哪些地址可以访问
    mapping (bytes32 => Addresses) functionAddress;
    
    // configure access role for function
    // if assistant, _function = assistant's address + function hash
    bytes32 public constant CONFIGURE_FUNCTION_ROLE = keccak256("CONFIGURE_FUNCTION_ROLE");
    function configureFunctionRole(bytes32 _function, bytes32 _role, OpMode _opMode) authFunctionHash(CONFIGURE_FUNCTION_ROLE) public { 
        Roles storage funcRole = functionRoles[_function];
        if (_opMode == OpMode.Add) {
            if (!funcRole.exist) {
                funcRole.exist = true;
                funcRole.value = new bytes32[](0);
                funcRole.value.push(_role);
                functionRoles[_function] = funcRole;
            } else {
                funcRole.value.push(_role);
            }
        } else if(_opMode == OpMode.Remove) {
            if (funcRole.exist) {
                for(uint i = 0; i < funcRole.value.length; i++) {
                    if (funcRole.value[i] == _role) {
                        delete funcRole.value[i];
                        break;
                    }
                }
            } 
        }
    }
    
    // configure role for address
    bytes32 public constant CONFIGURE_ADDRESS_ROLE = keccak256("CONFIGURE_ADDRESS_ROLE");
    function configureAddressRole(address _address, bytes32 _role, OpMode _opMode) authFunctionHash(CONFIGURE_ADDRESS_ROLE) public {
        Roles storage addrRole = addressRoles[_address];
        if (_opMode == OpMode.Add) {
            if (!addrRole.exist) {
                addrRole.exist = true;
                addrRole.value = new bytes32[](0);
                addrRole.value.push(_role);
                addressRoles[_address] = addrRole;
            } else {
                addrRole.value.push(_role);
            }
        } else if(_opMode == OpMode.Remove) {
            if (addrRole.exist) {
                for(uint i = 0; i < addrRole.value.length; i++) {
                    if (addrRole.value[i] == _role) {
                        delete addrRole.value[i];
                        break;
                    }
                }
            } 
        }
    }
    
    // configure address for function
    // if assistant, _function = assistant's address + function hash
    bytes32 public constant CONFIGURE_FUNCTION_ADDRESS = keccak256("CONFIGURE_FUNCTION_ADDRESS");
    function configureFunctionAddress(bytes32 _function, address _address, OpMode _opMode) authFunctionHash(CONFIGURE_FUNCTION_ADDRESS) public {
        Addresses storage addrFunc = functionAddress[_function];
        if (_opMode == OpMode.Add) {
              if (!addrFunc.exist) {
                addrFunc.exist = true;
                addrFunc.value = new address[](0);
                addrFunc.value.push(_address);
                functionAddress[_function] = addrFunc;
            } else {
                addrFunc.value.push(_address);
            }
        } else if(_opMode == OpMode.Remove) {
             if (addrFunc.exist) {
                for(uint i = 0; i < addrFunc.value.length; i++) {
                    if (addrFunc.value[i] == _address) {
                        delete addrFunc.value[i];
                        break;
                    }
                }
            } 
        }
    }
    
    // 判断msg.sender在不在设定地址中
    modifier authAddresses(address[] _addresses) {
        bool hasAuth =false;
        for(uint i = 0; i < _addresses.length; i++) {
            if (msg.sender == _addresses[i]) {
                hasAuth = true;
                break;
            }
        }
        
        require(hasAuth);
        _;
    }
    
    // 判断msg.sender的权限在不在设定权限中
    modifier authRoles(bytes32[] _roles) {
        // 获取caller的权限
        Roles storage addrRoleMap = addressRoles[msg.sender];
        require(addrRoleMap.exist);
        
        bool hasAuth =false;
        for(uint i = 0; i < _roles.length; i++) {
            for(uint j = 0; j < addrRoleMap.value.length; j++) {
                if (_roles[i] == addrRoleMap.value[j]) {
                    hasAuth = true;
                    break;
                }
            }
        }
        
        require(hasAuth);
        _;
    }
    
    // 自由配置functionHash可访问的地址和权限
    modifier authFunctionHash(bytes32 _function) {
        require(canPerform(msg.sender, _function));
        _;
    }
    
    function canPerform(address _caller, bytes32 _function) public view returns (bool) {
        // 判断地址是不是直接能够访问方法
        bool hasAuth = false;
        Addresses storage addrFuncMap = functionAddress[_function];
        if (addrFuncMap.exist) {
            for(uint i = 0; i < addrFuncMap.value.length; i++) {
                if (addrFuncMap.value[i] == _caller) {
                   hasAuth = true;
                   break;
                }
            }
        }
        
        if (!hasAuth) {
            // 获取方法的权限
            Roles storage funcRoleMap = functionRoles[_function];
            require(funcRoleMap.exist);
            
            // 获取caller的权限
            Roles storage addrRoleMap = addressRoles[_caller];
            require(addrRoleMap.exist);
            
            for(i = 0; i < funcRoleMap.value.length; i++) {
                for(uint j = 0; j < addrRoleMap.value.length; j++) {
                    if (funcRoleMap.value[i] == addrRoleMap.value[j]) {
                        hasAuth = true;
                        break;
                    }
                }
            }
        }
        
        return hasAuth;
    }
    
    // 获取地址对应的限列表
    function getAddressRoles(address _addr) public view returns (bytes32[]) {
        bytes32[] memory result;
        Roles memory roles = addressRoles[_addr];
        if (roles.exist) {
            result = new bytes32[](roles.value.length);
            for(uint i = 0; i < roles.value.length; i++) {
                 result[i] = roles.value[i];
            }
            return result;
        } else {
            return result;
        }
    }
    
}