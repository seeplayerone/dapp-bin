pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/utils/ds_math.sol";
import "./asi_registry.sol";

/**
    @dev Note this contract is only for TEST, should not be deployed on PROD
 */

contract FakeBTCIssuer is Template, DSMath {
    string private name = "Fake_BTC_ISSUER";
    uint32 private organizationID;
    uint32 private assetIndex;
    uint32 private assetType;
    uint256 private ASSET_BTC;
    
    Registry registry;

    address private hole = 0x660000000000000000000000000000000000000000;

    function() public payable {
        require(msg.assettype == ASSET_BTC);
    }

    function init(string _name) public {
        name = _name;
        registry = Registry(0x630000000000000000000000000000000000000065);
        organizationID = registry.registerOrganization(name, "Fake-Template-Name-For-Test");
        assetIndex = 1;
        assetType = 0;
        uint64 assetId = uint64(assetType) << 32 | uint64(organizationID);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);
        ASSET_BTC = asset;
        registry.newAsset("FBTC", "FBTC", "Fake BTC Pegging Coin", assetType, assetIndex, 0);
    }

    function mint(uint amount, address dest) public {
        flow.mintAsset(assetIndex, amount);
        registry.mintAsset(assetIndex, amount);
        dest.transfer(amount, ASSET_BTC);
    }

    function burn() public payable {
        require(msg.assettype == ASSET_BTC);
        registry.burnAsset(assetIndex,msg.value);
        hole.transfer(msg.value, msg.assettype);
    }

    function getAssetType() public view returns (uint256) {
        return ASSET_BTC;
    }

    function getAssetInfo(uint32 index)
        public
        view 
        returns (bool, string, string, string, uint32, uint)
    {
        (,,,,uint supply,) = registry.getAssetInfoByAssetId(organizationID, assetIndex);
        return (true, "FBTC", "FBTC", "Fake BTC Pegging Coin", 0, supply);
    }
}