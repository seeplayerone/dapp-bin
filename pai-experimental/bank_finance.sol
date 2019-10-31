pragma solidity 0.4.25;

import "../library/template.sol";
import "./pi_issuer.sol";
import "../library/acl_slave.sol";
import "./pi_setting.sol";
import "./pis_main.sol";
import "./pi_price_oracle.sol";

contract BankFinance is Template,ACLSlave,DSMath {
    constructor(address pisContract) public {
        master = ACLMaster(pisContract);
    }

    function() public payable {
    }

    function cashOut(uint96 assetGlobalId, uint amount, address dest) public auth("50%DirVote@Bank") {
        require(amount > 0);
        dest.transfer(amount,assetGlobalId);
    }
}