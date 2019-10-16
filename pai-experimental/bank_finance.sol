pragma solidity 0.4.25;

import "../library/template.sol";
import "./pai_issuer.sol";
import "../library/acl_slave.sol";
import "./3rd/math.sol";
import "./pai_setting.sol";
import "./pai_main.sol";
import "./price_oracle.sol";

contract Finance is Template,ACLSlave,DSMath {
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
    }

    function() public payable {
    }

    function cashOut(uint96 assetGlobalId, uint amount, address dest) public auth("Director@Bank") {
        require(amount > 0);
        dest.transfer(amount,assetGlobalId);
    }
}