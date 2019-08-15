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
    uint32 private organizationId;
    bool registed = false;
    string constant Cashier = "CASHIER";
    string constant Director = "DIRECTOR";
    string constant VoteContract = "VOTE";

    ///params for assets;
    uint32 private constant PIS = 0;
    uint32 private constant PAI = 1;
    struct AdditionalAssetInfo {
        uint64 assetLocalId;
        uint96 assetGlobalId;
    }
    mapping (uint32 => AdditionalAssetInfo) private Token; //name needs to be optimized；

    ///params for burn
    address private constant hole = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName, address[] _members)
        Organization(_organizationName, _members)
        public
    {
    }

    function init() public {
        require(!registed);
        organizationId = registry.registerOrganization(organizationName, templateName);
        configureFunctionAddressInternal(Cashier, 0x66b7bd27d59dd91d6c78b8402b90c820ab24cd073b, OpMode.Add);
        configureFunctionAddressInternal(Director, 0x666162077d9b76c1df3dd22dff1b3a9bc25348ea39, OpMode.Add);
        configureFunctionAddressInternal(VoteContract, 0x66da67bf3462da51f083b5fed4662973a62701a687, OpMode.Add);
        ///TODO the correct way of following three lines should be modifying the "organization.sol"
        configureFunctionRoleInternal(CONFIGURE_NORMAL_FUNCTION, "SUPER_ADMIN", OpMode.Remove);
        configureFunctionRoleInternal(CONFIGURE_ADVANCED_FUNCTION, "SUPER_ADMIN", OpMode.Remove);
        configureFunctionRoleInternal(CONFIGURE_SUPER_FUNCTION, "SUPER_ADMIN", OpMode.Remove);
        
        registed = true;
    }

    function mintPIS(uint amount, address dest) public {
        if(issuedAssets[PIS].existed) {
            mint(PIS, amount);
        } else {
            create("PIS", "PIS", "Share of PAIDAO", 0, PIS, amount);
            Token[PIS].assetLocalId = uint64(issuedAssets[PIS].assetType) << 32 | uint64(organizationId);
            Token[PIS].assetGlobalId = uint96(Token[PIS].assetLocalId) << 32 | uint96(PIS);
        }
        dest.transfer(amount, Token[PIS].assetGlobalId);
    }

    function mintPAI(uint amount, address dest) public {
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
        hole.transfer(msg.value, msg.assettype);
    }

    /// only for debug
    function getOrganizationId() public view returns(uint32) {
        return organizationId;
    }

    function deposit() public payable {
    }

    function getAdditionalAssetInfo(uint32 _assetIndex) public view returns (uint, uint) {
        return (Token[_assetIndex].assetLocalId,Token[_assetIndex].assetGlobalId);
    }

    uint256 private state = 0;
    function plusOne() public authFunctionHash(Cashier) {
        state = state + 1;
    }

    function plusTen() public authFunctionHash(Director) {
        state = state + 10;
    }

    function plusHundred() public authFunctionHash(VoteContract) {
        state = state + 100;
    }

    function getStates() public view returns (uint256) {
        return state;
    }

    function configFuncAddr(address _contract, address _caller, string _str) public {
        configureFunctionAddressInternal(
            StringLib.strConcat(StringLib.convertAddrToStr(_contract),_str),
            _caller,
            OpMode.Add);
    }
}