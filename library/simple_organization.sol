pragma solidity ^0.4.25;

import "github.com/evilcc2018/dapp-bin/library/organization.sol";

/// @dev this is a sample to demostrate how to create a simple organization contract on Asimov
///  it is recommended to inherit Oragnization contract which is provided by Asimov Tech Team
contract SimpleOrganization is Organization {

    /// @dev aclAddresses and aclRoles are used to demostrate the ACL capibility
    address[] aclAddresses;
    string[] aclRoles;

    string public constant ROLE_SAMPLE = "ROLE_SAMPLE";
    string public constant FUNCTION_HASH_SAMPLE = "FUNCTION_HASH_SAMPLE";

    uint32 assetIndex = 1;

    /// @dev constructor of the contract
    ///  initial acl settings are configured in the constructor
    constructor(string organizationName, address[] _members) Organization(organizationName, _members) 
    public {
        aclAddresses = new address[](0);
        aclAddresses.push(msg.sender);

        aclRoles = new string[](0);
        aclRoles.push(ROLE_SAMPLE);

        configureAddressRoleInternal(msg.sender, ROLE_SAMPLE, OpMode.Add);
        configureFunctionRoleInternal(FUNCTION_HASH_SAMPLE, ROLE_SAMPLE, OpMode.Add);
    }

    /// @dev register the organization
    ///  an organization id is assigned after successful registration,
    ///  which is the prerequisite of issuing assets
    function registerMe() public authAddresses(aclAddresses) {
        register();
    }

    /// @dev issue new asset
    function issueNewAsset(string name, string symbol, string desc) public authRoles(aclRoles) {
        /// divisible asset with initial amount 10000
        create(name, symbol, desc, 0, assetIndex, 10000);
        assetIndex ++;
    }

    /// @dev issue more asset
    function issueMoreAsset(uint32 index) public authFunctionHash(FUNCTION_HASH_SAMPLE) {
        /// issue 10000 more asset on the given index
        mint(index, 10000);
    }
    
    /// @dev transfer asset
    function transferAsset(address to, uint256 asset, uint256 amount) public authRoles(aclRoles) {
        transfer(to, asset, amount);
    }
    
}