pragma solidity 0.4.25;

/// @dev the Registry interface
///  Registry is a system contract, an organization needs to register before issuing assets
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
     function newAsset(string name, string symbol, string description, uint32 assetType, uint32 assetIndex, uint amountOrVoucherId) external;
     function mintAsset(uint32 assetIndex, uint amountOrVoucherId) external;
     function burnAsset(uint32 assetIndex, uint amount) external;
     function getAssetInfoByAssetId(uint32 organizationId, uint32 assetIndex)
        external 
        view 
        returns(bool, string, string, string, uint, uint[]);
}