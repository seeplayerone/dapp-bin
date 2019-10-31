pragma solidity 0.4.25;

import "../library/template.sol";
import "./pai_issuer.sol";
import "../library/acl_slave.sol";
import "./pai_setting.sol";
import "./pai_main.sol";
import "./price_oracle.sol";

contract BankFinance is Template,ACLSlave,DSMath {
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
    }

    function() public payable {
    }

    function cashOut(uint96 assetGlobalId, uint amount, address dest) public auth("50%DirVote@Bank") {
        require(amount > 0);
        dest.transfer(amount,assetGlobalId);
    }
}