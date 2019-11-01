pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";
import "./asi_registry.sol";

contract PAIIssuer is Template, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    uint32 private assetType = 0;
    uint32 private assetIndex = 0;
    bool private registed = false;
    Registry registry;

    ///params for PAI;
    uint96 public PAIGlobalId;

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName, address pisContract) public
    {
        organizationName = _organizationName;
        master = ACLMaster(pisContract);
    }

    function init() public {
        require(!registed);
        registry = Registry(0x630000000000000000000000000000000000000065);
        organizationId = registry.registerOrganization(organizationName, templateName);
        uint64 PAILocalId = (uint64(assetType) << 32 | uint64(organizationId));
        PAIGlobalId = uint96(PAILocalId) << 32 | uint96(assetIndex);
        registry.newAsset("PAI", "PAI", "PAI Stable Coin", assetType, assetIndex, 0);
        registed = true;
    }

    function mint(uint amount, address dest) public auth("Minter@STCoin") {
        flow.mintAsset(assetIndex, amount);
        registry.mintAsset(assetIndex, amount);
        dest.transfer(amount, PAIGlobalId);
    }

    function burn() public payable {
        require(msg.assettype == PAIGlobalId,
                "Only PAI can be burned!");
        registry.burnAsset(assetIndex,msg.value);
        zeroAddr.transfer(msg.value, PAIGlobalId);
    }

    function totalSupply() public view returns(uint supply) {
        (,,,,supply,) = registry.getAssetInfoByAssetId(organizationId,assetIndex);
    }
}