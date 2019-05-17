pragma solidity 0.4.25;

import "./template.sol";
import "./acl.sol";
import "./asset.sol";

/// @dev the Registry interface
///  Registry is a system contract
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
     function renameOrganization(string organizationName) external;
}

/// @title Simple organization which inherits Template, it has capabilities to:
///  - register to Registry and create/mint assets on Flow chain
///  - provide basic permission management through ACL contract
contract Organization is Template, ACL, Asset {
    string internal organizationName;
    Registry internal registry;
    
    /// organization members related
    address[] members;
    address[] invitees;
    string[] memberRoles;
    string private constant MEMBER_ROLES = "MEMBER_ROLES";
    string private constant INVITEES_ROLES = "INVITEES_ROLES";
    string private constant SUPER_ADMIN = "SUPER_ADMIN";
    
    /// invited members, but have not joined the organization
    mapping(address => bool) inviteesMap;
    
    /// @dev initialization function module to support complex business requirements during organization startup
    ///  which contains an initialized state, an initialize() function and a hasInitialized() modifier
    bool internal initialized;
    
    modifier hasInitialized() {
        require(initialized);
        _;
    }
    
    /// event of invite new member
    event invite(address invitee);
    
    /// @dev constructor
    /// @param _organizationName organization name
    /// @param _members initialization members
    constructor(string _organizationName, address[] _members) public {
        organizationName = _organizationName;
        registry = Registry(0x6314696e93ed4e41aebc95c5b042f18c9c367df535);
        
        /// init members and acl control
        memberRoles = new string[](0);
        memberRoles.push(MEMBER_ROLES);
        invitees = new address[](0);
        members = new address[](0);
        members.push(msg.sender);
        if (_members.length > 0) {
            for (uint i = 0; i < _members.length; i++) {
                members.push(_members[i]);
                configureAddressRoleInternal(_members[i], MEMBER_ROLES, OpMode.Add);
            }
        }
        
        /// default permission management settings, which grants the contract creator the "super admin" role
        configureAddressRoleInternal(msg.sender, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_NORMAL_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADVANCED_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_SUPER_FUNCTION, SUPER_ADMIN, OpMode.Add);
    }
    
    function initialize() public {
        initialized = true;
    }
    
    /// @dev invite new member to the organization
    /// @param memberAddress new member address
    function inviteMember(address memberAddress) internal authRoles(memberRoles) {
        if (!inviteesMap[memberAddress]) {
            inviteesMap[memberAddress] = true;
            invitees.push(memberAddress);
            configureAddressRoleInternal(memberAddress, INVITEES_ROLES, OpMode.Add);
            emit invite(memberAddress);
        }
    }
    
    /// @dev invited member joined the organization
    function join() internal authAddresses(invitees) {
        inviteesMap[msg.sender] = false;
        members.push(msg.sender);
        configureAddressRoleInternal(msg.sender, MEMBER_ROLES, OpMode.Add);
    }
    
    /// @dev existing member exit current organization
    function exit() internal authAddresses(members) {
        uint length = members.length;
        for (uint i = 0; i < length; i++) {
            if (msg.sender == members[i]) {
                delete members[i];
                if (i != length-1) {
                    members[i] = members[length-1];
                    delete members[length-1];
                }
                members.length--;
                break;
            }
        }
    }
    
    /// @dev register to Registry Center
    function register() internal returns(uint32) {
        return registry.registerOrganization(organizationName, templateName);
    }
    
    /// @dev rename organization name
    function rename(string newOrganizationName) internal {
        organizationName = newOrganizationName;
        registry.renameOrganization(newOrganizationName);
    }
    
    /// @dev create an asset
    /// @param assetType divisible 0, indivisible 1
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or the unique voucher id of asset
    function create(string name, string symbol, string description, uint32 assetType, uint32 assetIndex,
        uint256 amountOrVoucherId) internal {
        flow.createAsset(assetType, assetIndex, amountOrVoucherId);
        newAsset(name, symbol, description, assetType, assetIndex, amountOrVoucherId);
    }

    /// @dev mint an asset
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or the unique voucher id of asset
    function mint(uint32 assetIndex, uint256 amountOrVoucherId) internal {
        flow.mintAsset(assetIndex, amountOrVoucherId);
        updateAsset(assetIndex, amountOrVoucherId);
    }
    
    /// @dev transfer an asset
    /// @param to the destination address
    /// @param asset combined of assetType（divisible 0, indivisible 1）、
    ///     organizationId（organization id）、assetIndex（asset index in the organization）
    /// @param amount amount of asset to transfer (or the unique voucher id for an indivisible asset)    
    function transfer(address to, uint256 asset, uint256 amount) internal {
        to.transfer(amount, asset);
    }
    
    /// @dev whether an asset can be transferred or not, called when RISTRICTED bit is set
    ///     this function can be called by chain code or internal "transfer" implementation
    /// @param transferAddress in or out address
    /// @param assetIndex asset index
    /// @return success
    function canTransfer(uint32 assetIndex, address transferAddress)
        internal
        view
        returns(bool)
    {
        canTransferAsset(assetIndex, transferAddress);
    }
    
    /// @dev add an address to whitelist
    /// @param assetIndex asset index 
    /// @param newAddress the address to add
    /// @return success
    function authAddressToWhitelist(uint32 assetIndex, address newAddress)
        internal
        returns (bool)
    {
        return addAddressToWhitelist(assetIndex, newAddress);
    }
    
    /// @dev remove an address from whitelist
    /// @param assetIndex asset index 
    /// @param existingAddress the address to remove 
    /// @return success
    function deleteAddressFromWhitelist(uint32 assetIndex, address existingAddress)
        internal
        returns (bool)
    {
        return removeAddressFromWhitelist(assetIndex, existingAddress);
    }
    
    /// @dev get issued assets indexes
    /// @return success asset indexes
    function getTotalIssuedIndexes() internal view returns(bool, uint32[]) {
        return getIssuedIndexes();
    }
    
     /// @dev show create and mint history of an asset
     /// @param assetIndex index of an asset
     /// @return success,name,amount or voucherIds
    function showCreateAndMintHistoryOfAnAsset(uint32 assetIndex)
        internal
        view
        returns(bool, string, uint[])
    {
        return getCreateAndMintHistoryOfAnAsset(assetIndex);
    }
    
    /// @dev show asset info
    /// @param assetIndex asset index in the organization
    /// @return (isSuccess, assetName, assetSymbol, assetDesc, assetType, totalIssued)
    function getAssetDetail(uint32 assetIndex)
        internal
        view
        returns (bool, string, string, string, uint32, uint)
    {
        return getAssetInfo(assetIndex);
    }

}
