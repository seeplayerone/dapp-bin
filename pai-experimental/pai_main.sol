pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_master.sol";
import "./registry.sol";


contract PAIDAO is Template, DSMath, ACLMaster {
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
        registry.newAsset("PIS", "PIS", "Share of PAIDAO", assetType, assetIndex,0);   
        registed = true;
    }

    function mint(uint amount, address dest) public auth("DirPisVote") {
        mintInternal(amount, dest);
    }

    function autoMint(uint amount, address dest) public auth("FinanceContract") {
        mintInternal(amount, dest);
    }

    function mintInternal(uint amount, address dest) internal {
        flow.mintAsset(assetIndex, amount);
        registry.mintAsset(assetIndex, amount);
        dest.transfer(amount, PISGlobalId);
    }

    function burn() public payable {
        require(msg.assettype == PISGlobalId,
                "Only PIS can be burned!");
        registry.burnAsset(assetIndex,msg.value);
        zeroAddr.transfer(msg.value, PISGlobalId);
    }

    function totalSupply() public view returns(uint supply) {
        (,,,,supply,) = registry.getAssetInfoByAssetId(organizationId,assetIndex);
    }
}