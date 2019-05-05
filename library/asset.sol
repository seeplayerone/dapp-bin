pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";

contract Asset {
    
    /// @dev full information of an asset
    struct AssetInfo {
        /// basic information
        string name;
        string symbol;
        string description;
        /// properties of an asset
        /// asset type contains DIVISIBLE + ANONYMOUS + RESTRICTED
        uint32 assetType;
        
        /// total amount issued on a divisible asset OR total count issued on an indivisible asset
        uint totalIssued;

        /// 流通白名单
        mapping (address => bool) whitelist;
        /// all voucherIds
        uint[] voucherIds;
        
        bool existed;
    }
    
    /// all assets issued by the organization
    uint32[] internal issuedIndexes;
    /// assetIndex -> AssetInfo
    mapping (uint32 => AssetInfo) internal issuedAssets;
    
    /// @dev new an asset
    /// @param name asset name
    /// @param symbol asset symbol
    /// @param description asset description
    /// @param assetType asset properties, divisible, anonymous and restricted circulation
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or voucherId of asset to create
    function newAsset(string name, string symbol, string description, uint32 assetType, uint32 assetIndex,
        uint256 amountOrVoucherId)
        internal
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(!assetInfo.existed, "asset already existed");

        assetInfo.name = name;
        assetInfo.symbol = symbol;
        assetInfo.description = description;
        assetInfo.assetType = assetType;
        
        if (0 == getDivisibleBit(assetType)) {
            assetInfo.totalIssued = amountOrVoucherId; 
        } else if (1 == getDivisibleBit(assetType)) {
            assetInfo.totalIssued = SafeMath.add(assetInfo.totalIssued, 1);
            assetInfo.voucherIds.push(amountOrVoucherId);
        }
        assetInfo.existed = true;
        issuedIndexes.push(assetIndex);
    }

    /// @dev update an asset
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or voucherId of asset to mint 
    ///     (or the unique voucher id for an indivisible asset)    
    function updateAsset(uint32 assetIndex, uint256 amountOrVoucherId)
        internal
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        if (0 == getDivisibleBit(assetInfo.assetType)) {
            assetInfo.totalIssued = SafeMath.add(assetInfo.totalIssued, amountOrVoucherId);
        } else if (1 == getDivisibleBit(assetInfo.assetType)) {
            assetInfo.totalIssued = SafeMath.add(assetInfo.totalIssued, 1);
            assetInfo.voucherIds.push(amountOrVoucherId);
        }
    }
    
    /// @dev whether an asset can be transferred or not, called when RISTRICTED bit is set
    /// @dev this function can be called by chain code or internal "transfer" implementation
    /// @param transferAddress in or out address
    /// @param assetIndex asset index
    /// @return success
    function canTransfer(address transferAddress, uint32 assetIndex)
        internal
        view
        returns(bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return false;
        }
        
        /// restricted asset
        if (2 == getRestrictedBit(assetInfo.assetType)) {
            if (!assetInfo.whitelist[transferAddress]) {
                return false;
            }
        }
        
        return true;
    }
    
    /// @dev add an address to whitelist
    /// @dev should be ACLed
    /// @param assetIndex asset index 
    /// @param newAddress the address to add
    function addAddressToWhitelist(uint32 assetIndex, address newAddress)
        internal
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");

        assetInfo.whitelist[newAddress] = true;
        return true;
    }

    /// @dev remove an address from whitelist
    /// @dev should be ACLed
    /// @param assetIndex asset index 
    /// @param existingAddress the address to remove   
    function removeAddressFromWhitelist(uint32 assetIndex, address existingAddress)
        internal
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        assetInfo.whitelist[existingAddress] = false;
        return true;
    }
    
    /// @dev get asset name by asset index
    /// @param assetIndex asset index 
    function getAssetInfo(uint32 assetIndex) internal view returns (bool, string, string, string) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return (false, "", "", "");
        }
        
        return (true, assetInfo.name, assetInfo.symbol, assetInfo.description);
    }
    
    /// @dev get asset type by asset index
    /// @param assetIndex asset index 
    function getAssetType(uint32 assetIndex) internal view returns (bool, uint32) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return (false, 0);
        }
        
        return (true, assetInfo.assetType);
    }

    /// @dev get total amount/count issued on an asset
    /// @param assetIndex asset index 
    function getTotalIssued(uint32 assetIndex) internal view returns (bool, uint) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return (false, 0);
        }
        
        return (true, assetInfo.totalIssued);
    }

    /// @dev internal method: get property of isDivisible from assetType
    function getDivisibleBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 1;
    }
    
    /// @dev internal method: get property of isRestricted from assetType
    function getRestrictedBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 2;
    }
    
}
