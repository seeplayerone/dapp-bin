pragma solidity 0.4.25;

import "./acl_master.sol";

/**
    ACL Master/Slave provides a basic structure for permission control.

    We can define Permission Group in ACL Master. A PG contains a list of addresses and a Superior which is also a PG.
    A PG is managed by addresses defined in its Superior PG.
 */
 
contract ACLSlave {
    ACLMaster public master;
    modifier auth(string role) {
        require(master.canPerform(role, msg.sender));
        _;
    }
}