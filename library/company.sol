pragma solidity 0.4.25;

import "./organization.sol";

/// @dev The purpose of this contract is to set a standard on how to manage various assets for an organization
///  the abstract of asset on Flow is defined in AssetInfo struct, which contains basic information, asset properties and others
///  an organization can create new assets and mint existing assets; and an asset owner can redeem or transfer an asset
///  the asset issuer (the organization) can determine whether an asset can be transferred depending on the asset properties (asset type, whitelist, tag, etc)
contract Company is Organization {
    
    /// Compnay的ACL需要和Organization结合考虑，暂时先去掉
    address[] superAdmins;
    
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

        /// properties of an asset
        /// asset type contains DIVISIBLE + ANONYMOUS + RESTRICTED
        uint32 assetType;

        /// whitelist control, which is the default RISTRICTION type
        bool isTxinRestrictedToWhitelist;
        bool isTxoutRestrictedToWhitelist;
        mapping (address => bool) whitelist;

        /// tag: field for each issuer to engrave extra information
        /// bytes32 而不应该是 bytes32[]
        bytes32[] tag;

        /// total amount issued on a divisible asset OR total count issued on an indivisible asset
        uint totalIssued;
        /// all vouchers issued on an indivisible asset
        /// voucher id => voucher object
        mapping (uint => Voucher) issuedVouchers;

        bool existed;
    }
    
    /// all assets issued by the organization
    uint32[] issuedIndexes;
    /// assetIndex -> AssetInfo
    mapping (uint32 => AssetInfo) issuedAssets;
    
    /// @dev constructor of the contract
    ///  initial acl settings are configured in the constructor
    constructor(string organizationName) Organization(organizationName) public {
        /// make the contract creator as super admin to simplify testing
        superAdmins = new address[](0);
        superAdmins.push(msg.sender);
    }
    
    /// 这个函数不需要存在
    /// @dev register to Registry Center
    function registerOrganization() public authAddresses(superAdmins) {
        register();
    }
    
    /// @dev create an asset
    /// @param name asset name
    /// @param symbel asset symbol
    /// @param description asset description
    /// @param assetType asset properties, divisible, anonymous and restricted circulation
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or voucherId of asset to create
    ///     (or the unique voucher id for an indivisible asset)
    /// @param isTxinRestrictedToWhitelist whether the whitelist restriction applies to txin
    /// @param isTxoutRestrictedToWhitelist whether the whitelist restriction applies to txout
    /// @param tag extra properteis special to an asset
    /// @param voucherHash hash of an indivisible asset properties to check integrity
    function create(string name, string symbol, string description, uint32 assetType, uint32 assetIndex,
        uint256 amountOrVoucherId, bool isTxinRestrictedToWhitelist, bool isTxoutRestrictedToWhitelist, 
        bytes32 tag, bytes32 voucherHash)
        public
        authAddresses(superAdmins)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(!assetInfo.existed, "asset already existed");
        /// check the scope of assetType if match isTxinRestrictedToWhitelist and isTxoutRestrictedToWhitelist
        /// 没有完全匹配条件
        if (0 == scopeBits(assetType)) {
            require(isTxinRestrictedToWhitelist && isTxoutRestrictedToWhitelist);
        }
        if (4 == scopeBits(assetType)) {
            require(isTxoutRestrictedToWhitelist);
        }
        if (8 == scopeBits(assetType)) {
            require(isTxinRestrictedToWhitelist);
        }
        if (12 == scopeBits(assetType)) {
            require(isTxinRestrictedToWhitelist || isTxoutRestrictedToWhitelist);
        }
        
        /// create asset to utxo
        /// 需要判断是否执行成功，成功了才有下面的一系列操作
        create(assetType, assetIndex, amountOrVoucherId);

        assetInfo.name = name;
        assetInfo.symbol = symbol;
        assetInfo.description = description;
        assetInfo.assetType = assetType;
        assetInfo.isTxinRestrictedToWhitelist = isTxinRestrictedToWhitelist;
        assetInfo.isTxoutRestrictedToWhitelist = isTxoutRestrictedToWhitelist;
        assetInfo.tag.push(tag);
        
        if (0 == isDivisibleBit(assetType)) {
            assetInfo.totalIssued = amountOrVoucherId; 
        } else if (1 == isDivisibleBit(assetType)) {
            assetInfo.totalIssued = 1;
            /// 理论上来讲不会出现voucherId已经存在的情况，不然上面的create会失败
            Voucher storage voucher = assetInfo.issuedVouchers[amountOrVoucherId];
            require(!voucher.existed, "voucher already existed");
            voucher.voucherHash = voucherHash;
            voucher.existed = true;
        }
        assetInfo.existed = true;
        issuedIndexes.push(assetIndex);
    }

    /// @dev mint an asset
    /// @param assetIndex asset index in the organization
    /// @param amountOrVoucherId amount or voucherId of asset to mint 
    ///     (or the unique voucher id for an indivisible asset)    
    function mint(uint32 assetIndex, uint256 amountOrVoucherId, bytes32 tag, bytes32 voucherHash)
        public
        authAddresses(superAdmins)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        /// mint an asset
        /// 需要判断成功失败，如上
        mint(assetIndex, amountOrVoucherId);
        
        uint32 isDivisible = isDivisibleBit(assetInfo.assetType);
        if (0 == isDivisible) {
            /// uint的运算全都需要使用safemath
            assetInfo.totalIssued = assetInfo.totalIssued + amountOrVoucherId;
        } else if (1 == isDivisible) {
            assetInfo.totalIssued++;
            Voucher storage voucher = assetInfo.issuedVouchers[amountOrVoucherId];
            /// 同上，理论上不会运行到这里
            require(!voucher.existed, "voucher already existed");
            voucher.voucherHash = voucherHash;
            voucher.existed = true;
        }
        assetInfo.tag.push(tag);
    }
    
    /// @dev transfer an asset 
    /// @param to the destination address
    /// @param asset combined of assetType（divisible 0, indivisible 1）、
    ///     organizationId（organization id）、
    ///     assetIndex（asset index in the organization）
    /// @param amountOrVoucherId amount or voucherId of asset to transfer
    ///     (or the unique voucher id for an indivisible asset)    
    /// 这个方法不需要
    function transferAsset(address to, bytes12 asset, uint256 amountOrVoucherId)
        public
        authAddresses(superAdmins)
    {
        transfer(to, asset, amountOrVoucherId);
    }
    
    /// @dev whether an asset can be transferred or not, called when RISTRICTED bit is set
    /// @dev this function can be called by chain code or internal "transfer" implementation
    /// @param transferAddress in or out address
    /// @param assetIndex asset index
    /// @return success
    /// 这个方法整体逻辑判断似乎有问题
    function canTransfer(address transferAddress, uint32 assetIndex)
        public
        view
        returns(bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        if (!assetInfo.existed) {
            return false;
        }
        /// must be restricted asset
        /// 为什么返回false?
        if (2 != isRestrictedBit(assetInfo.assetType)) {
            return false;
        }
        /// address must be in whitelist
        /// 为什么返回false?
        if (!assetInfo.whitelist[transferAddress]) {
            return false;
        }
        
        bool isTxinRestricted = assetInfo.isTxinRestrictedToWhitelist;
        bool isTxoutRestricted = assetInfo.isTxoutRestrictedToWhitelist;
        /// get scope
        uint32 scope = scopeBits(assetInfo.assetType);
        bool result;
        if (0 == scope) {
            result = (isTxinRestricted && isTxoutRestricted);
        }
        if (4 == scope) {
            result = isTxoutRestricted;
        }
        if (8 == scope) {
            result = isTxinRestricted;
        }
        if (12 == scope) {
            result = (isTxinRestricted || isTxoutRestricted);
        }
        return result;
    }
    
    /// @dev add an address to whitelist
    /// @dev should be ACLed
    /// @param assetIndex asset index 
    /// @param newAddress the address to add
    function addAddressToWhitelist(uint32 assetIndex, address newAddress)
        public
        authAddresses(superAdmins)
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        /// 判断条件有问题
        require(assetInfo.existed, "asset not exist");

        if (!assetInfo.whitelist[newAddress]) {
            assetInfo.whitelist[newAddress] = true;
        }
        return true;
    }

    /// @dev remove an address from whitelist
    /// @dev should be ACLed
    /// @param assetIndex asset index 
    /// @param existingAddress the address to remove   
    function removeAddressFromWhitelist(uint32 assetIndex, address existingAddress)
        public
        authAddresses(superAdmins)
        returns (bool)
    {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        require(assetInfo.existed, "asset not exist");
        
        if (assetInfo.whitelist[existingAddress]) {
            delete assetInfo.whitelist[existingAddress];
        }
        return true;
    }
    
    /// @dev get asset name by asset index
    /// @param assetIndex asset index 
    function getAssetInfo(uint32 assetIndex) public view returns (string, string, string) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        /// view方法内部不需要require
        require(assetInfo.existed, "asset not exist");
        
        return (assetInfo.name, assetInfo.symbol, assetInfo.description);
    }
    
    /// @dev get asset type by asset index
    /// @param assetIndex asset index 
    function getAssetType(uint32 assetIndex) public view returns (uint32) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        /// view方法内部不需要require
        require(assetInfo.existed, "asset not exist");
        
        return assetInfo.assetType;
    }

    /// @dev get total amount/count issued on an asset
    /// @param assetIndex asset index 
    function getTotalIssued(uint32 assetIndex) public view returns (uint) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        /// view方法内部不需要require
        require(assetInfo.existed, "asset not exist");
        
        return assetInfo.totalIssued;
    }

    /// @dev get voucher hash by asset index and voucher id
    /// @param assetIndex asset index 
    /// @param voucherId voucher id
    function getVoucherHash(uint32 assetIndex, uint voucherId) public view returns (bytes32) {
        AssetInfo storage assetInfo = issuedAssets[assetIndex];
        /// view方法内部不需要require
        require(assetInfo.existed, "asset not exist");
        
        Voucher storage voucher = assetInfo.issuedVouchers[voucherId];
        /// view方法内部不需要require
        require(voucher.existed, "voucher not exist");
        return voucher.voucherHash;
    }

    /// is开头的方法应该返回true/false
    /// @dev internal method: get property of isDivisible from assetType
    function isDivisibleBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 1;
    }
    
    /// @dev internal method: get property of isRestricted from assetType
    function isRestrictedBit(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 2;
    }
    
    /// @dev internal method: get property of a\scope from assetType
    function scopeBits(uint32 assetType) internal pure returns(uint32) {
        uint32 lastFourBits = assetType & 15;
        return lastFourBits & 12;
    }
    
}
