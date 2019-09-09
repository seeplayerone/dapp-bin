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
    uint64 PISLocalId;
    uint96 PISGlobalId;

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
        PISLocalId = uint64(0) << 32 | uint64(organizationId);
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

    // function mintPAI(uint amount, address dest) public //authFunctionHash("ISSURER")
    // {
    //     if(issuedAssets[PAI].existed) {
    //         mint(PAI, amount);
    //     } else {
    //         create("PAI", "PAI", "PAI Stable Coin", 0, PAI, amount);
    //         Token[PAI].assetLocalId = uint64(issuedAssets[PAI].assetType) << 32 | uint64(organizationId);
    //         Token[PAI].assetGlobalId = uint96(Token[PAI].assetLocalId) << 32 | uint96(PAI);
    //     }
    //     dest.transfer(amount, Token[PAI].assetGlobalId);
    // }

    // function burn() public payable{
    //     require(msg.assettype == Token[PIS].assetGlobalId ||
    //             msg.assettype == Token[PAI].assetGlobalId,
    //             "Only PAI or PIS can be burned!");
    //     if(msg.assettype == Token[PIS].assetGlobalId){
    //         issuedAssets[PIS].totalIssued = sub(issuedAssets[PIS].totalIssued, msg.value);
    //     }else{
    //         issuedAssets[PAI].totalIssued = sub(issuedAssets[PAI].totalIssued, msg.value);
    //     }
    //     zeroAddr.transfer(msg.value, msg.assettype);
    // }

    // function everyThingIsOk() public {
    //     require(msg.sender == tempAdmin, "Only temp admin can configure");
    //     tempAdmin = zeroAddr;
    // }
}