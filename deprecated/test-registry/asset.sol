pragma solidity 0.4.25;

import "../safe_math.sol";

/// @title The Asset contract is designed to store extra information of assets issued by an Organization
///  Detail information for an asset include:
///  - name/symbol/description
///  - assetType (inherited from UTXO)
///  - total issued & issuance history
///  - whitelist for restricted asset

contract Asset {
    
    /// full information of an asset
    struct AssetInfo {
        /// basic information
        string name;
        string symbol;
        string description;

        /// maps to AssetType field in UTXO
        /// DIVISIBLE + ANONYMOUS + RESTRICTED
        uint32 assetType;
        /// total amount issued on a divisible asset OR total count issued on an indivisible asset
        uint totalIssued;
        
        /// whitelist for restricted asset
        mapping (address => bool) whitelist;
        /// issuance history
        uint[] amountOrVoucherIds;
        
        bool existed;
    }
    
    /// all assets issued by the organization
    uint32[] internal issuedIndexes;
    /// assetIndex -> AssetInfo
    mapping (uint32 => AssetInfo) internal issuedAssets;
    
    /**
     * @dev create a new asset; called when asi.createAsset instruction is invoked
     * 
     * @param name asset name
     * @param symbol asset symbol
     * @param description asset description
     * @param assetType basic properties, divisible, anonymous and restricted
     * @param assetIndex asset index in the organization
     * @param amountOrVoucherId amount or voucherId of asset
     */
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
            assetInfo.totalIssued = 1;
        }
        assetInfo.amountOrVoucherIds.push(amountOrVoucherId);
        
        assetInfo.existed = true;
        issuedIndexes.push(assetIndex);
    }
   
    /**
     * @dev update an asset; called when asi.mintAsset instruction is invoked
     * 
     * @param assetIndex asset index in the organization
     * @param amountOrVoucherId amount or voucherId of asset 
     */
    function updateAsset(uint32 assetIndex, uint256 amountOrVoucherId)
        internal
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        if (0 == getDivisibleBit(assetInfo.assetType)) {
            assetInfo.totalIssued = SafeMath.add(assetInfo.totalIssued, amountOrVoucherId);
        } else if (1 == getDivisibleBit(assetInfo.assetType)) {
            assetInfo.totalIssued = SafeMath.add(assetInfo.totalIssued, 1);
        }
        assetInfo.amountOrVoucherIds.push(amountOrVoucherId);
    }

    /**
     * @dev check whether an asset can be transferred or not, called when RISTRICTED bit is set
     *  this function can be called by chain code or internal "transfer" implementation
     * 
     * @param transferAddress in or out address
     * @param assetIndex asset index
     * @return success
     */
    function canTransferAsset(uint32 assetIndex, address transferAddress)
        public
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
 
    /**
     * @dev add an address to whitelist
     * 
     * @param assetIndex asset index 
     * @param newAddress the address to add
     * @return success
     */
    function addAddressToWhitelist(uint32 assetIndex, address newAddress)
        internal
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");

        assetInfo.whitelist[newAddress] = true;
        return true;
    }
 
    /**
     * @dev remove an address from whitelist
     * 
     * @param assetIndex asset index 
     * @param existingAddress the address to remove 
     * @return success
     */
    function removeAddressFromWhitelist(uint32 assetIndex, address existingAddress)
        internal
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        assetInfo.whitelist[existingAddress] = false;
        return true;
    }
 
    /**
     * @dev get issued asset indexes
     * 
     * @return success, asset indexes
     */
    function getIssuedIndexes() internal view returns(bool, uint32[]) {
        if (issuedIndexes.length <= 0) {
            return (false, new uint32[](0));
        }
        
        return (true, issuedIndexes);
    }
 
    /**
     * @dev get asset basic information
     * 
     * @param assetIndex asset index
     * @return success,name,symbol,description,assetType,totalIssued
     */
    function getAssetInfo(uint32 assetIndex)
        public
        view 
        returns (bool, string, string, string, uint32, uint)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return (false, "", "", "", 0, 0);
        }
        
        return (true, assetInfo.name, assetInfo.symbol, assetInfo.description, assetInfo.assetType, assetInfo.totalIssued);
    }
    
    /**
     * @dev get create and mint history of an asset
     * 
     * @param assetIndex index of an asset
     * @return success,name,issuance history
     */
    function getCreateAndMintHistory(uint32 assetIndex)
        public
        view 
        returns(bool, string, uint[])
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return (false, "", new uint[](0));
        }
        
        return (true, assetInfo.name, assetInfo.amountOrVoucherIds);
    }

    /**
     * @dev internal method: get property of isDivisible from assetType
     */
    function getDivisibleBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 1;
    }
    
    /**
     * @dev internal method: get property of isRestricted from assetType
     */
    function getRestrictedBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 2;
    }
    
}
