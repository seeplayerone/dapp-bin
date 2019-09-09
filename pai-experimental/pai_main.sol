pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "../library/organization.sol";
// import "./string_utils.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_master.sol";
import "github.com/evilcc2018/dapp-bin/library/asset.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/registry.sol";


contract PAIDAO is Template, Asset, DSMath, ACLMaster {
    using StringLib for string;
    
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    bool registed = false;
    //address public tempAdmin;

    ///params for PIS;
    uint96 public PISGlobalId;

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName) public
    {
        organizationName = _organizationName;
        //tempAdmin = msg.sender;
    }

    function init() public {
        require(!registed);
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        organizationId = registry.registerOrganization(organizationName, templateName);
        registed = true;

        uint64 PISLocalId = (uint64(1) << 32 | uint64(organizationId));
        PISGlobalId = uint96(PISLocalId) << 32 | uint96(0);
    }

    function mint(uint amount, address dest) public auth("ADMIN")
    {
        if(issuedAssets[0].existed) {
            flow.mintAsset(0, amount);
            updateAsset(0, amount);
        } else {
            flow.createAsset(0, 0, amount);
            newAsset("PIS", "PIS", "Share of PAIDAO", 0, 0, amount);
        }
        dest.transfer(amount, PISGlobalId);
    }

    function burn() public payable{
        require(msg.assettype == PISGlobalId,
                "Only PIS can be burned!");
        issuedAssets[0].totalIssued = sub(issuedAssets[0].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, msg.assettype);
    }
}