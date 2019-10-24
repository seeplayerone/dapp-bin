pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";
import "./3rd/math.sol";
import "./registry.sol";

contract BankIssuer is Template, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    Registry registry;
    bool private registed = false;

    mapping(uint32 => uint96) public AssetGlobalId;
    mapping(uint32 => bool) public exist;

    /// crate asset
    event CreateAsset(bytes12);

    ///params for burn
    address private constant zeroAddr = 0x660000000000000000000000000000000000000000;
    
    constructor(string _organizationName, address paiMainContract) public
    {
        organizationName = _organizationName;
        master = ACLMaster(paiMainContract);
    }

    function init() public {
        require(!registed);
        registry = Registry(0x630000000000000000000000000000000000000065);
        organizationId = registry.registerOrganization(organizationName, templateName);
        registed = true;
    }

    /**
     * @dev Create New Asset
     *
     * @param name asset name
     * @param symbol asset symbol
     * @param description asset description
     */
    function createAsset(string name, string symbol, string description, uint32 assetIndex) public auth("BusinessContract@Bank") {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");
        require(!exist[assetIndex], "assetIndex has already existed");
        registry.newAsset(name, symbol, description, 0, assetIndex, 0);
        uint64 assetId = uint64(0) << 32 | uint64(organizationId);
        AssetGlobalId[assetIndex] = uint96(assetId) << 32 | uint96(assetIndex);
        exist[assetIndex] = true;
        emit CreateAsset(bytes12(AssetGlobalId[assetIndex]));
    }

    function mint(uint32 assetIndex, uint amount, address dest) public auth("BusinessContract@Bank") {
        require(exist[assetIndex],"not valid assetIndex");
        flow.mintAsset(assetIndex, amount);
        registry.mintAsset(assetIndex, amount);
        dest.transfer(amount, AssetGlobalId[assetIndex]);
    }

    function burn() public payable {
        uint32 assetIndex = uint32(msg.assettype);
        require(msg.assettype == AssetGlobalId[assetIndex],"asset not supported");
        registry.burnAsset(assetIndex,msg.value);
        zeroAddr.transfer(msg.value, AssetGlobalId[assetIndex]);
    }

    function totalSupply(uint32 assetIndex) public view returns(uint supply) {
        (,,,,supply,) = registry.getAssetInfoByAssetId(organizationId,assetIndex);
    }
}