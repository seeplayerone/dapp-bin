pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/asset.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/registry.sol";

contract BankIssuer is Template, Asset, DSMath, ACLSlave {
    ///params for organization
    string public organizationName;
    uint32 public organizationId;
    bool private registed = false;

    mapping(uint => uint96) AssetGlobalId;
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

    function mint(uint32 assetIndex, uint amount, address dest) public auth("BusinessContract@Bank") {
        if(!issuedAssets[assetIndex].existed) {
            return;
        }
        flow.mintAsset(assetIndex, amount);
        updateAsset(assetIndex, amount);
        dest.transfer(amount, AssetGlobalId[assetIndex]);
    }

    function burn(uint32 assetIndex) public payable {
        require(msg.assettype == AssetGlobalId[assetIndex],"index and asset not match");
        issuedAssets[assetIndex].totalIssued = sub(issuedAssets[assetIndex].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, AssetGlobalId[assetIndex]);
    }
}