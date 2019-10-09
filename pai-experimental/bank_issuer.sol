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
    uint public assetIndex = 0;

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
     * @param assetType asset type, DIVISIBLE + ANONYMOUS + RESTRICTED
     * @param assetIndex asset index in the organization
     * @param amountOrVoucherId amount or voucherId of asset
     */
    function createAsset(string name, string symbol, string description)
    public
    {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");
        assetIndex = add(assetIndex,1)

        newAsset(name, symbol, description, 0, assetIndex, 1);

        uint64 assetId = uint64(0) << 32 | uint64(organizationId);
        AssetGlobalId[assetIndex] = uint96(assetId) << 32 | uint96(assetIndex);

        zeroAddr.transfer(1, PAIGlobalId);
        emit CreateAsset(bytes12(AssetGlobalId[assetIndex]));
    }

    function mint(uint assetIndex, uint amount, address dest) public {
        if(!issuedAssets[assetIndex].existed) {
            return;
        } 
        flow.mintAsset(assetIndex, amount);
        updateAsset(assetIndex, amount);
        dest.transfer(amount, AssetGlobalId[assetIndex]);
    }

    function burn(uint assetIndex) public payable {
        require(msg.assettype == AssetGlobalId[assetIndex],"index and asset not match");
        issuedAssets[index].totalIssued = sub(issuedAssets[index].totalIssued, msg.value);
        zeroAddr.transfer(msg.value, PAIGlobalId);
    }
}