pragma solidity 0.4.25;

import "./organization.sol";

/// @dev NOT FINAL
contract Company is Organization {
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
    function getAssetName(uint32 assetIndex) external returns (string);

    /// @dev get asset symbol by asset index
    function getAssetSymbol(uint32 assetIndex) external returns (string);

    /// @dev get asset description by asset index
    function getAssetDescription(uint32 assetIndex) external returns (string);

    /// @dev get asset properties by asset index
    function getAssetType(uint32 assetIndex) external returns (int32);

    /// @dev get voucher hash by asset index and voucher id
    function getVoucherHash(uint32 assetIndex, uint64 voucherId) external returns (bytes32);

    /// @dev add or remove an address in whitelist
    /// @dev should be ACLed
    function updateWhitelist(uint32 assetIndex, address newAddress, OpMode addOrRemove) internal;

    /// @dev should move all asset related functions from Organization to Company or merge the code in Company to Organization
    function create(string name, string symbol, string description, uint32 assetType, uint32 assetIndex, uint amountOrVoucherId, bool isTxinRestrictedToWhitelist, bool isTxoutRestrictedToWhitelist) internal;

    /// @dev whether an asset can be transferred or not, called when RISTRICTED bit is set
    /// @dev this function can be called by chain code or internal "transfer" implementation
    /// @param assetIndex the asset index inside the organization
    /// @param from from who
    /// @param to to who
    /// @param amountOrVoucherId amount for a divisible asset; or voucher id for an indivisible asset
    function canTransfer(uint32 assetIndex, address from , address to, uint amountOrVoucherId) external returns (bool, bytes32);
    
}
