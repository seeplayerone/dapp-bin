pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_master.sol";
import "../library/asset.sol";
import "./3rd/math.sol";
import "./registry.sol";


contract PAIDAO is Template, Asset, DSMath, ACLMaster {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    uint32 private assetType = 0;
    uint32 private assetIndex = 0;
    bool private registed = false;
    Registry public registry;

    ///params for PIS;
    uint96 public PISGlobalId;

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName) public
    {
        organizationName = _organizationName;
    }

    function init() public {
        require(!registed);
        registry = Registry(0x630000000000000000000000000000000000000065);
        organizationId = registry.registerOrganization(organizationName, templateName);
        uint64 PISLocalId = (uint64(assetType) << 32 | uint64(organizationId));
        PISGlobalId = uint96(PISLocalId) << 32 | uint96(assetIndex);
        registed = true;
    }

    function mint(uint amount, address dest) public auth("PISVOTE") {
        mintInternal(amount, dest);
    }

    function autoMint(uint amount, address dest) public auth("FinanceContract") {
        mintInternal(amount, dest);
    }

    function mintInternal(uint amount, address dest) internal {
        if(issuedAssets[assetIndex].existed) {
            flow.mintAsset(assetIndex, amount);
            updateAsset(assetIndex, amount);
        } else {
            flow.createAsset(assetType, assetIndex, amount);
            newAsset("PIS", "PIS", "Share of PAIDAO", assetType, assetIndex, amount);
            registry.newAsset("PIS", "PIS", "Share of PAIDAO", assetType, assetIndex);
        }
        dest.transfer(amount, PISGlobalId);
    }

    function burn() public payable {
        require(msg.assettype == PISGlobalId,
                "Only PIS can be burned!");
        issuedAssets[0].totalIssued = sub(issuedAssets[0].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, PISGlobalId);
    }
}