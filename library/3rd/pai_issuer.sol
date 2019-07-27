pragma solidity 0.4.25;

//import "../template.sol";
//import "./math.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/3rd/math.sol";


/// @dev the Registry interface
///  Registry is a system contract, an organization needs to register before issuing assets
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
     function renameOrganization(string organizationName) external;
}

contract PAIIssuer is Template, DSMath {
    string private name = "PAI_ISSUER";
    uint32 private orgId;
    uint32 private index;
    uint32 private assetType;
    uint256 private PAI_ASSET_TYPE;
    
    uint private totalSupply = 0;

    bool private firstTry;

    address private hole = 0x000000000000000000000000000000000000000000;

    function init(string _name) public {
        name = _name;
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        orgId = registry.registerOrganization(name, templateName);
        index = 1;
        assetType = 0;
        uint64 assetId = uint64(assetType) << 32 | uint64(orgId);
        uint96 asset = uint96(assetId) << 32 | uint96(index);
        PAI_ASSET_TYPE = asset;
        firstTry = true;
    }

    function mint(uint amount, address dest) public {
        if(firstTry) {
            firstTry = false;
            flow.createAsset(assetType, index, amount);
        } else {
            flow.mintAsset(index, amount);
        }
        dest.transfer(amount, PAI_ASSET_TYPE);
        totalSupply = add(totalSupply, amount);
    }

    function burn() public payable {
        require(msg.assettype == PAI_ASSET_TYPE);
        hole.transfer(msg.value, PAI_ASSET_TYPE);
        totalSupply = sub(totalSupply, msg.value);
    }

    function getAssetType() public view returns (uint256) {
        return PAI_ASSET_TYPE;
    }

    function getAssetInfo(uint32 assetIndex)
        public
        view 
        returns (bool, string, string, string, uint32, uint)
    {
        return (true, "PAI", "PAI", "PAI Stable Coin", 0, totalSupply);
    }
}