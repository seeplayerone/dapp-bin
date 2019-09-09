pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/asset.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/registry.sol";

contract PAIIssuer is Template, Asset, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    uint32 private assetType = 0;
    uint32 private assetIndex = 0;
    bool registed = false;

    ///params for PIS;
    uint96 private PAIGlobalId;

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

    function mint(uint amount, address dest) public auth("ISSUECALLER") {
        //require(canPerform(bytes(ADMIN), msg.sender));
        if(issuedAssets[assetIndex].existed) {
            flow.mintAsset(assetIndex, amount);
            updateAsset(assetIndex, amount);
        } else {
            flow.createAsset(assetType, assetIndex, amount);
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

    function getAssetType() public view returns (uint96) {
        return PAIGlobalId;
    }
}