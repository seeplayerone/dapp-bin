pragma solidity 0.4.25;

import "./template.sol";
import "./acl.sol";
import "./asset.sol";

/// @dev the Registry interface
///  Registry is a system contract, an organization needs to register before issuing assets
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
     function renameOrganization(string organizationName) external;
}

/// @title basic organization which inherits Template, ACL and Asset, it has capabilities to:
///  - register and create/mint assets on Asimov chain
///  - implement basic permission framework through ACL contract
///  - save all information of issued assets through Asset contract
///  - add new members through invitation
contract Organization is Template, ACL, Asset {
    string internal organizationName;
    Registry internal registry;
    
    /// organization members related
    address[] members;
    address[] invitees;
    string[] memberRoles;
    string private constant MEMBER_ROLE = "MEMBER_ROLE";
    string private constant SUPER_ADMIN = "SUPER_ADMIN";
    
    /// existing members, initially there or joined the organization by invitation
    mapping(address => bool) membersMap;
    /// invited members, an invitee become a member after accepting the invitation
    mapping(address => bool) inviteesMap;
    
    /// event of invite new member
    event invite(address invitee);
    
    /// @dev constructor
    /// @param _organizationName organization name
    /// @param _members initial members
    constructor(string _organizationName, address[] _members) public {
        organizationName = _organizationName;
        registry = Registry(0x65);
        
        /// initial members and acl control
        memberRoles = new string[](0);
        memberRoles.push(MEMBER_ROLE);
        invitees = new address[](0);
        members = new address[](0);
        members.push(msg.sender);
        configureAddressRoleInternal(msg.sender, MEMBER_ROLE, OpMode.Add);
        if (_members.length > 0) {
            for (uint i = 0; i < _members.length; i++) {
                members.push(_members[i]);
                membersMap[_members[i]] = true;
                configureAddressRoleInternal(_members[i], MEMBER_ROLE, OpMode.Add);
            }
        }
        
        /// default permission settings, which grants the contract creator the "super admin" role
        configureAddressRoleInternal(msg.sender, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_NORMAL_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_ADVANCED_FUNCTION, SUPER_ADMIN, OpMode.Add);
        configureFunctionRoleInternal(CONFIGURE_SUPER_FUNCTION, SUPER_ADMIN, OpMode.Add);
    }
    
    /// @dev invite new member to the organization
    /// @param memberAddress new member address
    function inviteMember(address memberAddress) internal authRoles(memberRoles) {
        if (!inviteesMap[memberAddress] && !membersMap[memberAddress]) {
            inviteesMap[memberAddress] = true;
            invitees.push(memberAddress);
            emit invite(memberAddress);
        }
    }
    
    /// @dev join the organization
    function join() internal authAddresses(invitees) {
        inviteesMap[msg.sender] = false;
        uint length = invitees.length;
        for (uint i = 0; i < length; i++) {
            if (msg.sender == invitees[i]) {
                if (i != length-1) {
                    invitees[i] = invitees[length-1];
                }
                delete invitees[length-1];
                invitees.length--;
                break;
            }
        }
        members.push(msg.sender);
        membersMap[msg.sender] = true;
        configureAddressRoleInternal(msg.sender, MEMBER_ROLE, OpMode.Add);
    }
    
    /// @dev exit the organization
    function exit() internal authAddresses(members) {
        uint length = members.length;
        for (uint i = 0; i < length; i++) {
            if (msg.sender == members[i]) {
                if (i != length-1) {
                    members[i] = members[length-1];
                }
                delete members[length-1];
                members.length--;
                membersMap[msg.sender] = false;
                break;
            }
        }
    }
    
    /// @dev register to Registry Center
    ///  organization will get a unique id after registration, which is the prerequisite of issuing assets
    function register() internal returns(uint32) {
        return registry.registerOrganization(organizationName, templateName);
    }
    
    /// @dev rename organization
    function rename(string newOrganizationName) internal {
        organizationName = newOrganizationName;
        registry.renameOrganization(newOrganizationName);
    }
    
    /// @dev create an asset
    /// @param assetType asset type
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
    /// @param asset asset type + org id + asset index
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
    
}
