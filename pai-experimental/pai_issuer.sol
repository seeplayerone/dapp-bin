pragma solidity 0.4.25;

// import "../library/template.sol";
// import "./3rd/math.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/RegisteryInterface.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

contract PAIIssuer is Template, DSMath {
    string private name = "PAI_ISSUER";
    uint32 private orgnizationID;
    uint32 private assetIndex;
    uint32 private assetType;
    uint256 private ASSET_PAI;
    
    uint private totalSupply = 0;

    bool private firstTry;
    address private hole = 0x660000000000000000000000000000000000000000;

    function() public payable {
        require(msg.assettype == ASSET_PAI);
    }

    function init(string _name) public {
        name = _name;
        /// TODO organization registration should be done in DAO
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        orgnizationID = registry.registerOrganization(name, templateName);
        assetIndex = 1;
        assetType = 0;
        uint64 assetId = uint64(assetType) << 32 | uint64(orgnizationID);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);
        ASSET_PAI = asset;
        firstTry = true;
    }

    function mint(uint amount, address dest) public {
        if(firstTry) {
            firstTry = false;
            flow.createAsset(assetType, assetIndex, amount);
        } else {
            flow.mintAsset(assetIndex, amount);
        }
        dest.transfer(amount, ASSET_PAI);
        totalSupply = add(totalSupply, amount);
    }

    function burn() public payable {
        require(msg.assettype == ASSET_PAI);
        hole.transfer(msg.value, msg.assettype);
        totalSupply = sub(totalSupply, msg.value);
    }

    function getAssetType() public view returns (uint256) {
        return ASSET_PAI;
    }

    function getAssetInfo(uint32 index)
        public
        view 
        returns (bool, string, string, string, uint32, uint)
    {
        return (true, "PAI", "PAI", "PAI Stable Coin", 0, totalSupply);
    }
}