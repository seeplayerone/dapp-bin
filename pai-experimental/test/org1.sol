pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
//import "github.com/evilcc2018/dapp-bin/pai-experimental/registeryInterface.sol";

/// @dev the Registry interface
///  Registry is a system contract, an organization needs to register before issuing assets
interface RegistryKUKU {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
}

contract ORG1 is Template {
    function() public payable {
        require(msg.assettype == ASSET_BTC);
    }

    function init(string _name) public {
        name = _name;
        RegistryKUKU registry = RegistryKUKU(0x630000000000000000000000000000000000000065);
        orgnizationID = registry.registerOrganization(name, templateName);
    }

}