pragma solidity 0.4.25;

// import "./3rd/math.sol";
// import "../library/organization.sol";
// import "./string_utils.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/organization.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";

contract PAIDAO is Organization, DSMath {
    using StringLib for string;
    
    ///params for organization
    uint32 public organizationId;
    bool registed = false;
    address public tempAdmin;

    ///params for assets;
    uint32 private constant PIS = 0;
    uint32 private constant PAI = 1;
    struct AdditionalAssetInfo {
        uint64 assetLocalId;
        uint96 assetGlobalId;
    }
    mapping (uint32 => AdditionalAssetInfo) public Token; //name needs to be optimized；

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName, address[] _members)
        Organization(_organizationName, _members)
        public
    {
        tempAdmin = msg.sender;
    }

    function init() public {
        require(!registed);
        organizationId = registry.registerOrganization(organizationName, templateName);
        ///TODO the correct way of following three lines should be modifying the "organization.sol"
        configureFunctionRoleInternal(CONFIGURE_NORMAL_FUNCTION, "SUPER_ADMIN", OpMode.Remove);
        configureFunctionRoleInternal(CONFIGURE_ADVANCED_FUNCTION, "SUPER_ADMIN", OpMode.Remove);
        configureFunctionRoleInternal(CONFIGURE_SUPER_FUNCTION, "SUPER_ADMIN", OpMode.Remove);

        registed = true;
    }
    function configFunc(string _function, address _address, OpMode _opMode) public authFunctionHash("VOTE") {
        configureFunctionAddressInternal(_function, _address, _opMode);
    }

    function configOthersFunc(address _contract, address _caller, string _function, OpMode _opMode) public authFunctionHash("VOTE") {
        configureFunctionAddressInternal(
            StringLib.strConcat(StringLib.convertAddrToStr(_contract),_function),
            _caller,
            _opMode);
    }

    function tempConfig(string _function, address _address, OpMode _opMode) public {
        require(msg.sender == tempAdmin, "Only temp admin can configure");
        this.configFunc(_function, _address, _opMode);
    }

    function tempOthersConfig(address _contract, address _caller, string _function, OpMode _opMode) public {
        require(msg.sender == tempAdmin, "Only temp admin can configure");
        this.configOthersFunc(_contract, _caller, _function, _opMode);
    }

    function tempMintPIS(uint amount, address dest) public {
        require(msg.sender == tempAdmin, "Only temp admin can mint");
        this.mintPIS(amount, dest);
    }

    function mintPIS(uint amount, address dest) public authFunctionHash("VOTE") {
        if(issuedAssets[PIS].existed) {
            mint(PIS, amount);
        } else {
            create("PIS", "PIS", "Share of PAIDAO", 0, PIS, amount);
            Token[PIS].assetLocalId = uint64(issuedAssets[PIS].assetType) << 32 | uint64(organizationId);
            Token[PIS].assetGlobalId = uint96(Token[PIS].assetLocalId) << 32 | uint96(PIS);
        }
        dest.transfer(amount, Token[PIS].assetGlobalId);
    }

    function mintPAI(uint amount, address dest) public authFunctionHash("ISSURER") {
        if(issuedAssets[PAI].existed) {
            mint(PAI, amount);
        } else {
            create("PAI", "PAI", "PAI Stable Coin", 0, PAI, amount);
            Token[PAI].assetLocalId = uint64(issuedAssets[PAI].assetType) << 32 | uint64(organizationId);
            Token[PAI].assetGlobalId = uint96(Token[PAI].assetLocalId) << 32 | uint96(PAI);
        }
        dest.transfer(amount, Token[PAI].assetGlobalId);
    }

    function burn() public payable{
        require(msg.assettype == Token[PIS].assetGlobalId ||
                msg.assettype == Token[PAI].assetGlobalId,
                "Only PAI or PIS can be burned!");
        if(msg.assettype == Token[PIS].assetGlobalId){
            issuedAssets[PIS].totalIssued = sub(issuedAssets[PIS].totalIssued, msg.value);
        }else{
            issuedAssets[PAI].totalIssued = sub(issuedAssets[PAI].totalIssued, msg.value);
        }
        zeroAddr.transfer(msg.value, msg.assettype);
    }

    function everyThingIsOk() public {
        require(msg.sender == tempAdmin, "Only temp admin can configure");
        tempAdmin = zeroAddr;
    }
}