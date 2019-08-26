pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";

//import "./string_utils.sol";
//import "./template.sol";

/// @dev ACL interface
///  ACL is provided by the organization contract
interface ACL {
    function canPerform(address _caller, string _functionHash) external view returns (bool);
}

contract testACL is Template {
    using StringLib for string;
    ACL acl;
    /// organization contract
    address organizationContract;
    
    function setOrganization(address _organizationContract) public {
        organizationContract = _organizationContract;
        acl = ACL(_organizationContract);
    }

    /// get the organization contract address
    function getOrganization() public view returns (address){
        return organizationContract;
    }

    modifier authFunctionHash(string func) {
        require(acl.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this),func)));
        _;
    }

    uint256 private state = 0;
    function plusOne() public authFunctionHash("p1") {
        state = state + 1;
    }

    function plusTen() public authFunctionHash("p10") {
        state = state + 10;
    }

    function plusHundred() public authFunctionHash("p100") {
        state = state + 100;
    }

    function getStates() public view returns (uint256) {
        return state;
    }

    function getFuncStr(string _str) public view returns (string) {
        return StringLib.strConcat(StringLib.convertAddrToStr(this),_str);
    }
}




