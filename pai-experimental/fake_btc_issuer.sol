pragma solidity 0.4.25;

// import "../library/template.sol";
// import "./3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";


/// @dev the Registry interface
///  Registry is a system contract, an organization needs to register before issuing assets
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
}

contract FakeBTCIssuer is Template, DSMath {
    string private name = "Fake_BTC_ISSUER";
    uint32 private orgnizationID;
    uint32 private assetIndex;
    uint32 private assetType;
    uint256 private ASSET_BTC;
    
    uint private totalSupply = 0;

    bool private firstTry;
    address private hole = 0x660000000000000000000000000000000000000000;

    function() public payable {
        require(msg.assettype == ASSET_BTC);
    }

    function init(string _name) public {
        name = _name;
        /// TODO organization registration should be done in DAO
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        orgnizationID = registry.registerOrganization(name, "Fake-Template-Name-For-Test");
        assetIndex = 1;
        assetType = 0;
        uint64 assetId = uint64(assetType) << 32 | uint64(orgnizationID);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);
        ASSET_BTC = asset;
        firstTry = true;
    }

    function mint(uint amount, address dest) public {
        if(firstTry) {
            firstTry = false;
            flow.createAsset(assetType, assetIndex, amount);
        } else {
            flow.mintAsset(assetIndex, amount);
        }
        dest.transfer(amount, ASSET_BTC);
        totalSupply = add(totalSupply, amount);
    }

    function burn(uint amount) public {
        totalSupply = sub(totalSupply, amount);
    }

    function getAssetType() public view returns (uint256) {
        return ASSET_BTC;
    }

    function getAssetInfo(uint32 index)
        public
        view 
        returns (bool, string, string, string, uint32, uint)
    {
        return (true, "FBTC", "FBTC", "Fake BTC Pegging Coin", 0, totalSupply);
    }
}