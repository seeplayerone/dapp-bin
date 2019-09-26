pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";


contract FakePaiDao is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        return true;
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        return true;
    }
}