pragma solidity 0.4.25;

import "./acl_master.sol";

contract ACLSlave {
    ACLMaster public master;
    modifier auth(string role) {
        require(master.canPerform(role, msg.sender));
        _;
    }
    modifier auth(bytes role) {
        require(master.canPerform(role, msg.sender));
        _;
    }
}