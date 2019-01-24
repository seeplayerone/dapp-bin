pragma solidity 0.4.25;

import "./organization.sol";

/// @dev NOT FINAL
contract Company {
    /// @dev We define a voucher as an element of an indivisible asset
    ///  a hash is kept to validate the integrity for off chain data
    struct Voucher {
        bytes32 voucherHash;
        bool existed;
    }

    /// @dev full information of an asset
    struct AssetInfo {
        /// basic information
        string name;
        string symbol;
        string description;

        /// properties kept in UTXO
        /// currently it is DIVISIBLE + ANONYMOUS + RESTRICTED
        uint32 assetType;

        /// whitelist control, which is the default restriction type
        bool isTxinRestrictedToWhitelist;
        bool isTxoutRestrictedToWhitelist;
        mapping (address=>bool) whitelist;

        /// tag: to be explained by each individual issuer
        bytes32 tag;

        /// total amount issued on a divisible asset
        /// total count issued on an indivisible asset
        uint totalIssued;
        /// all vouchers issued on an indivisible asset
        /// voucher id => voucher object
        mapping (uint=>Voucher) issuedVouchers;

        bool existed;
    }

    /// all assets issued by the organization
    uint32[] issuedIndexes;
    mapping (uint32=>AssetInfo) issuedAssets;

    /// Standard Functions Provided to Application Layer

    /// @dev get asset name by asset index
    /// @param assetIndex asset index 
    function getName(uint32 assetIndex) external returns (string);

    /// @dev get asset symbol by asset index
    /// @param assetIndex asset index 
    function getSymbol(uint32 assetIndex) external returns (string);

    /// @dev get asset description by asset index
    /// @param assetIndex asset index 
    function getDescription(uint32 assetIndex) external returns (string);

    /// @dev get asset properties by asset index
    /// @param assetIndex asset index 
    function getAssetType(uint32 assetIndex) external returns (int32);

    /// @dev get total amount/count issued on an asset
    /// @param assetIndex asset index 
    function getTotalIssued(uint32 assetIndex) external returns (uint);

    /// @dev get voucher hash by asset index and voucher id
    /// @param assetIndex asset index 
    /// @param voucherId voucher id
    function getVoucherHash(uint32 assetIndex, uint voucherId) external returns (bytes32);

    /// @dev add an address to whitelist
    /// @dev should be ACLed
    /// @param assetIndex asset index 
    /// @param newAddress the address to add 
    function addAddressToWhitelist(uint32 assetIndex, address newAddress) internal returns (bool);

    /// @dev create an asset with given information
    /// @param name asset name
    /// @param symbol asset symbol
    /// @param description asset description
    /// @param assetType asset properties
    /// @param assetIndex asset index, which is unique inside the organization
    /// @param amountOrVoucherId amount for an divisible asset and voucher id for an indivisible asset
    /// @param isTxinRestrictedToWhitelist is the sender restricted by whitelist when transferring the asset
    /// @param isTxoutRestrictedToWhitelist is the recepient restricted by the whitelist when transferring the asset
    /// @param tag extra 32 bytes for the issuer to engrave specific tags to the asset
    /// @return success + fail reason + amount/voucher id 
    function create(string name, string symbol, string description, 
                    uint32 assetType, uint32 assetIndex, uint amountOrVoucherId, 
                    bool isTxinRestrictedToWhitelist, bool isTxoutRestrictedToWhitelist, 
                    bytes32 tag) internal
                    returns (bool, bytes32, uint);

    /// @dev mint an existing asset
    /// @param assetIndex asset index
    /// @param amountOrVoucherId amount of asset to mint (or the unique voucher id for an indivisible asset)    
    function mint(uint32 assetIndex, uint amountOrVoucherId) internal;
    
    /// @dev transfer an asset
    /// @param to the recepient address
    /// @param assetId asset Id = organization id + asset index
    /// @param amountOrVoucherId amount of asset to transfer (or the unique voucher id for an indivisible asset)    
    function transfer(address to, int64 assetId, uint amountOrVoucherId) internal;

    /// @dev redeem an asset by amount or by voucher id
    /// @param assetIndex asset index
    /// @param amountOrVoucherId amount of asset to mint (or the unique voucher id for an indivisible asset)
    function redeem(int32 assetIndex, uint amountOrVoucherId) internal;

    /// @dev whether an asset can be transferred or not, called when RISTRICTED bit is set
    /// @dev this function can be called by chain code or internal "transfer" implementation
    /// @param assetIndex the asset index inside the organization
    /// @param from from who
    /// @param to to who
    /// @param amountOrVoucherId amount for a divisible asset; or voucher id for an indivisible asset
    /// @return success + fail reason
    function canTransfer(uint32 assetIndex, address from , address to, uint amountOrVoucherId) external returns (bool, bytes32);
    
}
