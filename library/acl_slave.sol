pragma solidity 0.4.25;

interface ACLMaster {
    function canPerform(string role, address _addr) external view returns (bool);
}

contract ACLSlave {
    ACLMaster public master;
    modifier auth(string role) {
        require(master.canPerform(role, msg.sender));
        _;
    }
}