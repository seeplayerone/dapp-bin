pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/interface.sol";

// /// @dev the Registry interface
// ///  Registry is a system contract, an organization needs to register before issuing assets
// interface RegistryKAKA {
//      function registerOrganization(string organizationName, string templateName) external returns(uint32);
// }

contract ORG2 is Template {
    function init(string _name) public {
        //RegistryKAKA registry = RegistryKAKA(0x630000000000000000000000000000000000000065);
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        registry.registerOrganization(_name, templateName);
    }

}