pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/asset.sol";
import "../library/acl_slave.sol";
import "./registry.sol";

contract BankIssuer is Template, Asset, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    bool private registed = false;

    mapping(uint => uint96) public AssetGlobalId;
    uint32 public assetIndex = 0; //asset index in the organization

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
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
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
    function createAsset(string name, string symbol, string description) public auth("DirectorVote@Bank")
    {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");
        assetIndex = assetIndex + 1;
        require(assetIndex != 0, "assetIndex has overflowed");
        newAsset(name, symbol, description, 0, assetIndex, 1000);
        flow.createAsset(0, assetIndex, 1000);
        uint64 assetId = uint64(0) << 32 | uint64(organizationId);
        AssetGlobalId[assetIndex] = uint96(assetId) << 32 | uint96(assetIndex);
        zeroAddr.transfer(1000, AssetGlobalId[assetIndex]);
        issuedAssets[assetIndex].totalIssued = 0;
        emit CreateAsset(bytes12(AssetGlobalId[assetIndex]));
    }

    function mint(uint32 _assetIndex, uint amount, address dest) public auth("BusinessContract@Bank") {
        if(!issuedAssets[_assetIndex].existed) {
            return;
        }
        flow.mintAsset(_assetIndex, amount);
        updateAsset(_assetIndex, amount);
        dest.transfer(amount, AssetGlobalId[_assetIndex]);
    }

    function burn(uint32 _assetIndex) public payable {
        require(msg.assettype == AssetGlobalId[_assetIndex],"index and asset not match");
        issuedAssets[_assetIndex].totalIssued = sub(issuedAssets[_assetIndex].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, AssetGlobalId[_assetIndex]);
    }
}