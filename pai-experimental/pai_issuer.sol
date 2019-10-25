pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/asset.sol";
import "../library/acl_slave.sol";
import "./registry.sol";

contract PAIIssuer is Template, Asset, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    uint32 private assetType = 0;
    uint32 private assetIndex = 0;
    bool private registed = false;

    ///params for PAI;
    uint96 public PAIGlobalId;

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName, address paiMainContract) public
    {
        organizationName = _organizationName;
        master = ACLMaster(paiMainContract);
    }

    function init() public {
        require(!registed);
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        organizationId = registry.registerOrganization(organizationName, templateName);
        uint64 PAILocalId = (uint64(assetType) << 32 | uint64(organizationId));
        PAIGlobalId = uint96(PAILocalId) << 32 | uint96(assetIndex);
        registed = true;
    }

    function mint(uint amount, address dest) public auth("PAIMINTER") {
        if(issuedAssets[assetIndex].existed) {
            flow.mintAsset(assetIndex, amount);
            updateAsset(assetIndex, amount);
        } else {
            flow.createAsset(assetType, assetIndex, amount);
            Registry registry = Registry(0x630000000000000000000000000000000000000065);
            registry.newAsset("PAI", "PAI", "PAI Stable Coin", assetType, assetIndex);            
            newAsset("PAI", "PAI", "PAI Stable Coin", assetType, assetIndex, amount);
        }
        dest.transfer(amount, PAIGlobalId);
    }

    function burn() public payable {
        require(msg.assettype == PAIGlobalId,
                "Only PAI can be burned!");
        issuedAssets[0].totalIssued = sub(issuedAssets[0].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, PAIGlobalId);
    }
}