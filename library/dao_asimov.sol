pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/string_utils.sol";
import "github.com/seeplayerone/dapp-bin/library/organization.sol";

//import "./string_utils.sol";
//import "./organization.sol";

interface SimpleVote {
    function setOrganization(address orgAddress) external;
}

contract Association is Organization {
    /// @dev president of the organization
    ///  there is only one president for the organization
    ///  array is used to support the authAddresses() modifier
    address[] presidents;
    
    /// members of the organization
    address[] members;
    
    /// whether the organization is registered
    bool hasRegistered;

    /// organization id is assigned by Registry system contract
    /// organization id is the prerequisite for issuing assets
    uint32 organizationId;
    
    /// map for quick reference
    mapping(address => bool) existingMembers;
    
    /// @dev EVENTS
    /// update members of the organization, including transferring the president role
    event UpdateMemberEvent(bool);
    /// rename the organization
    event RenameOrganizationEvent(bool);
    /// create an asset
    event CreateAssetEvent(bytes12);
    /// transfer asset
    event TransferSuccessEvent(bool);
    /// create vote contract
    event CreateVoteContract(address);
    
    /// @dev fallback function, which is set to payable to accept various Asimov assets
    ///  if you want to restrict the asset type, this is the place to call asi.asset instruction
    function() public payable{}

    string constant START_VOTE_FUNCTION = "START_VOTE_FUNCTION";
    string constant VOTE_FUNCTION = "VOTE_FUNCTION";

    string constant ASSET_VOTE_CONTRACT = "ASSET_VOTE_CONTRACT";

    address private assetVoteContractAddress;

    SimpleVote private assetVoteContract;

    constructor(string _organizationName, address[] _members, string voteTemplateName) 
        Organization(_organizationName, _members) 
        public payable
    {
        require(bytes(_organizationName).length > 0, "organization name should not be empty");

        /// by default, the contract creator becomes the president
        presidents = new address[](0);
        presidents.push(msg.sender);

        /// deploy a vote contract for asset creation
        assetVoteContractAddress =  flow.deployContract(1, voteTemplateName, "");
        assetVoteContract = SimpleVote(assetVoteContractAddress); 
        assetVoteContract.setOrganization(this);

        emit CreateVoteContract(assetVoteContractAddress);

        configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),START_VOTE_FUNCTION), msg.sender, OpMode.Add);
        configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),VOTE_FUNCTION), msg.sender, OpMode.Add);

        configureFunctionAddress(ASSET_VOTE_CONTRACT, assetVoteContractAddress, OpMode.Add);
    }
    
    /**
     * @dev get president
     */
    function getPresident() public view returns(address) {
        return presidents[0];
    }
    
    function getMembers() public view returns(address[]) {
        return members;
    }

    /**
     * @dev get organization Id
     */
    function getOrganizationId() public view returns(uint32) {
        return organizationId;
    }
    
    function getAssetVoteContract() public view returns(address) {
        return assetVoteContract;
    }

    /**
     * @dev rename organization
     *
     * @param newOrganizationName new name
     */
    function renameOrganization(string newOrganizationName) 
        public 
        authAddresses(presidents) 
    {
        rename(newOrganizationName);
        emit RenameOrganizationEvent(true);
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
        authFunctionHash(ASSET_VOTE_CONTRACT)
        public
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

        emit CreateAssetEvent(bytes12(asset));
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
        
        emit TransferSuccessEvent(true);
    }
    
    /**
     * @dev Transfer president role
     * 
     * @param newPresident address of the new president
     */
    function transferPresidentRole(address newPresident)
        public 
        authAddresses(presidents)
    {
        delete presidents[0];
        presidents.length--;
        presidents.push(newPresident);
        
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
                configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),START_VOTE_FUNCTION), newMembers[i], OpMode.Add);
                configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),VOTE_FUNCTION), newMembers[i], OpMode.Add);
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
                    configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),START_VOTE_FUNCTION), member, OpMode.Remove);
                    configureFunctionAddress(StringLib.strConcat(StringLib.convertAddrToStr(assetVoteContractAddress),VOTE_FUNCTION), member, OpMode.Remove);
                    if (i != length-1) {
                        members[i] = members[length-1];
                    }
                    delete members[length-1];
                    members.length--;
                    existingMembers[member] = false;
                    break;
                }
            }
        }
        emit UpdateMemberEvent(true);
    }    
}