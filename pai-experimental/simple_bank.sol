pragma solidity 0.4.25;

import "../library/organization.sol";

contract Bank is Organization {
    /// @dev president of the organization
    ///  there is only one president for the organization
    ///  array is used to support the authAddresses() modifier
    address[] presidents;

    /// members of the organization
    address[] members;
    /// map for quick reference
    mapping(address => bool) existingMembers;

    /// whether the organization is registered
    bool hasRegistered;

    /// organization id is assigned by Registry system contract
    /// organization id is the prerequisite for issuing assets
    uint32 organizationId;

    /// deposit addresses
    string[] depAddrs;

    /// map for member and deposit address
    mapping(address => string) mbr2dep;
    mapping(string => address) dep2mbr;

    /// @dev EVENTS
    /// update members of the organization, including transferring the president role
    event UpdateMemberEvent(bool);
    /// add new deposit address
    event AddDepositAddress(bool);
    /// allocate a deposit address to the sender
    event AllocateDepositAddress(string);
    /// crate asset
    event CreateAsset(bytes12);
    /// mint asset
    event MintAsset(uint);
    /// transfer asset
    event TransferAsset(address, uint);
    /// burn asset
    event BurnAsset(uint, uint);

    /// @dev fallback function, which is set to payable to accept various Asimov assets
    ///  if you want to restrict the asset type, this is the place to call asi.asset instruction
    function() public payable{}

    constructor(string _organizationName, address[] _members)
    Organization(_organizationName, _members)
    public payable
    {
        require(bytes(_organizationName).length > 0, "organization name should not be empty");

        /// by default, the contract creator becomes the president
        presidents = new address[](0);
        presidents.push(msg.sender);
        emit UpdateMemberEvent(true);
    }

    /**
     * @dev add members
     *
     * @param newMembers addresses of new members
     */
    function addNewMembers(address[] newMembers)
    public
    authAddresses(presidents)
    {
        uint length = newMembers.length;
        require(length > 0, "no addresses provided");

        for (uint i = 0; i < length; i++) {
            if (!existingMembers[newMembers[i]]) {
                members.push(newMembers[i]);
                existingMembers[newMembers[i]] = true;
            }
        }

        emit UpdateMemberEvent(true);
    }

    /**
     * @dev remove a member
     *
     * @param member address of the member to be removed
     */
    function removeMember(address member)
    public
    authAddresses(presidents)
    {
        if (existingMembers[member]) {
            uint length = members.length;
            for (uint i = 0; i < length; i++) {
                if (member == members[i]) {
                    if (i != length-1) {
                        members[i] = members[length-1];
                    }
                    members.length--;
                    existingMembers[member] = false;
                    break;
                }
            }
        }
        emit UpdateMemberEvent(true);
    }

    /**
     * @dev add new deposit address
     *
     * @param asset asset
     * @param depAddr new deposit address
     */
    function addDepositAddress(uint asset, string depAddr)
    public
    authAddresses(presidents)
    {
        require(bytes(depAddr).length > 0, "deposit address should not be empty");

        depAddrs.push(depAddr);
        emit AddDepositAddress(true);
    }

    /**
     * @dev allocate a deposit address to the sender
     *
     * @param asset asset
     */
    function allocateDepositAddress(uint asset)
    public
    {
        // only if the sender doesn't have a deposit address
        if (bytes(mbr2dep[msg.sender]).length == 0) {
            // find the first free deposit address
            for (uint i = 0; i < depAddrs.length; i++) {
                if (dep2mbr[depAddrs[i]] == 0) {
                    dep2mbr[depAddrs[i]] = msg.sender;
                    mbr2dep[msg.sender] = depAddrs[i];
                    break;
                }
            }
        }
        emit AllocateDepositAddress(mbr2dep[msg.sender]);
    }

    function createShare1(string name, string symbol, string description, uint32 assetType,
        uint32 assetIndex, uint amount, address to1, uint amount1)
    public
    {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");

        if (!hasRegistered) {
            organizationId = register();
            hasRegistered = true;
        }

        create(name, symbol, description, assetType, assetIndex, amount);

        uint64 assetId = uint64(assetType) << 32 | uint64(organizationId);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);
        emit CreateAsset(bytes12(asset));

        transfer(to1, asset, amount1);
        emit TransferAsset(to1, amount1);
    }

    function createShare2(string name, string symbol, string description, uint32 assetType,
        uint32 assetIndex, uint amount, address to1, uint amount1, address to2, uint amount2)
    public
    {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");

        if (!hasRegistered) {
            organizationId = register();
            hasRegistered = true;
        }

        create(name, symbol, description, assetType, assetIndex, amount);

        uint64 assetId = uint64(assetType) << 32 | uint64(organizationId);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);
        emit CreateAsset(bytes12(asset));

        transfer(to1, asset, amount1);
        emit TransferAsset(to1, amount1);

        transfer(to2, asset, amount2);
        emit TransferAsset(to2, amount2);
    }

    function mintShare1(uint32 assetIndex, uint asset, uint amount, address to1, uint amount1)
    public
    {
        mint(assetIndex, amount);
        emit MintAsset(amount);

        transfer(to1, asset, amount1);
        emit TransferAsset(to1, amount1);
    }

    function mintShare2(uint32 assetIndex, uint asset, uint amount, address to1, uint amount1, address to2, uint amount2)
    public
    {
        mint(assetIndex, amount);
        emit MintAsset(amount);

        transfer(to1, asset, amount1);
        emit TransferAsset(to1, amount1);

        transfer(to2, asset, amount2);
        emit TransferAsset(to2, amount2);
    }

    function transferShare2(uint asset, address to1, uint amount1, address to2, uint amount2)
    public
    {
        transfer(to1, asset, amount1);
        emit TransferAsset(to1, amount1);

        transfer(to2, asset, amount2);
        emit TransferAsset(to2, amount2);
    }

    /**
     * @dev Create New Asset
     *
     * @param name asset name
     * @param symbol asset symbol
     * @param description asset description
     * @param assetType asset type, DIVISIBLE + ANONYMOUS + RESTRICTED
     * @param assetIndex asset index in the organization
     * @param amountOrVoucherId amount or voucherId of asset
     */
    function createAsset(string name, string symbol, string description, uint32 assetType,
        uint32 assetIndex, uint amountOrVoucherId)
    public
    authAddresses(presidents)
    {
        require(bytes(name).length > 0, "asset requires a name");
        require(bytes(symbol).length > 0, "asset requires a symbol");

        if (!hasRegistered) {
            organizationId = register();
            hasRegistered = true;
        }

        create(name, symbol, description, assetType, assetIndex, amountOrVoucherId);

        uint64 assetId = uint64(assetType) << 32 | uint64(organizationId);
        uint96 asset = uint96(assetId) << 32 | uint96(assetIndex);

        emit CreateAsset(bytes12(asset));
    }

    /**
     * @dev Mint more existing asset
     *
     * @param assetIndex asset index in the organization
     * @param amountOrVoucherId amount or voucherId of asset
     */
    function mintAsset(uint32 assetIndex, uint amountOrVoucherId)
    public
    authAddresses(presidents)
    {
        mint(assetIndex, amountOrVoucherId);
        emit MintAsset(amountOrVoucherId);
    }

    /**
     * @dev Transfer asset
     *
     * @dev transfer an asset
     * @param to the destination address
     * @param asset asset type + org id + asset index
     * @param amountOrVoucherId amount of asset to transfer (or the unique voucher id for an indivisible asset)
     */
    function transferAsset(address to, uint asset, uint amountOrVoucherId)
    public
    authAddresses(presidents)
    {
        transfer(to, asset, amountOrVoucherId);
        emit TransferAsset(to, amountOrVoucherId);
    }

    /**
     * @dev Mint and transfer asset
     *
     * @dev mint and transfer an asset
     * @param txid txid of deposit transaction
     * @param depAddr the deposit address
     * @param asset asset type + org id + asset index
     * @param amountOrVoucherId amount of asset to transfer (or the unique voucher id for an indivisible asset)
     */
    function depositAsset(string txid, string depAddr, uint asset, uint amountOrVoucherId)
    public
    authAddresses(presidents)
    {
        require(bytes(txid).length > 0, "requires txid");
        mint(uint32(asset), amountOrVoucherId);
        transfer(dep2mbr[depAddr], asset, amountOrVoucherId);
        emit TransferAsset(dep2mbr[depAddr], amountOrVoucherId);
    }

    /**
     * @dev Mint and transfer asset
     *
     * @dev mint and transfer an asset
     * @param txid txid of deposit transaction
     * @param depAddr the deposit address
     * @param to the destination address
     * @param asset asset type + org id + asset index
     * @param amount amount of asset to transfer (or the unique voucher id for an indivisible asset)
     */
    function deposit(string txid, string depAddr, address to, uint asset, uint amount)
    public
    authAddresses(members)
    {
        require(bytes(txid).length > 0, "requires txid");
        require(bytes(depAddr).length > 0, "requires depAddr");
        mint(uint32(asset), amount);
        transfer(to, asset, amount);
        emit TransferAsset(to, amount);
    }

    function depositOne(address to, uint asset, uint amount)
    public
    {
        mint(uint32(asset), amount);
        transfer(to, asset, amount);
        emit TransferAsset(to, amount);
    }

    function depositMultiX(address addr1, uint amount1, address addr2, uint amount2, uint asset)
    public
    {
        mint(uint32(asset), amount1);
        transfer(addr1, asset, amount1);

        mint(uint32(asset), amount2);
        transfer(addr2, asset, amount2);
        emit TransferAsset(addr2, amount2);
    }

    function depositMultiY(address addr1, uint amount1, address addr2, uint amount2, uint asset)
    public
    {
        mint(uint32(asset), amount1 + amount2);

        transfer(addr1, asset, amount1);
        transfer(addr2, asset, amount2);
        emit TransferAsset(addr2, amount2);
    }

    /**
     * @dev burn asset
     *
     * @param recAddr receive address
     */
    function withdraw(string recAddr)
    public payable
    {
        require(bytes(recAddr).length > 0, "requires recAddr");
        transfer(0x660000000000000000000000000000000000000000, msg.assettype, msg.value);
        emit BurnAsset(msg.assettype, msg.value);
    }

    /**
     * @dev get president
     */
    function getPresident(uint index) public view returns(address)  {
        require(index < presidents.length);
        return presidents[index];
    }

    /**
     * @dev get member
     */
    function getMember(uint index) public view returns(address)  {
        require(index < members.length);
        return members[index];
    }

    /**
     * @dev get organizationId
     */
    function getOrganizationId() public view authAddresses(presidents) returns(uint32) {
        return organizationId;
    }

    function getDepAddr(uint index) public view returns(string) {
        return depAddrs[index];
    }

    function getDepForMbr(address member) public view returns(string) {
        return mbr2dep[member];
    }

    function getMbrForDep(string depAddr) public view returns(address) {
        return dep2mbr[depAddr];
    }
}

