pragma solidity 0.4.25;

<<<<<<< HEAD
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
=======
import "./pai_main.sol";
>>>>>>> 1fe0cfad4b8a655a254e6309fc30278620be3937


contract PaiDaoNoGovernance is PAIDAO {
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