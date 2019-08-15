pragma solidity 0.4.25;

// import "./3rd/math.sol";

import "github.com/evilcc/dapp-bin/pai-experimental/3rd/math.sol";

contract PAIIssuer is Organization, DSMath {
    ///about orgnization information
    string private name = "PAIDAO";
    uint32 private orgnizationID;

    ///enum AssetName {PIS, PAI}
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
        /// TODO
        /// for testing, the name can be rewritten by input argument,
        /// but when deployed on chain, the name should not be changeable.
        name = _name;

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

    function burn(uint amount) public {
        totalSupply = sub(totalSupply, amount);
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