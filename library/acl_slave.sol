pragma solidity 0.4.25;

interface ACLMaster {
    function canPerform(address _addr,string role) external view returns (bool);
}

contract ACLSlave {
    ACLMaster public master;
    modifier auth(string role) {
        require(master.canPerform(msg.sender,role));
        _;
    }
}