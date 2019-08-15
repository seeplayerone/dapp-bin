pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract test is Template {
    uint256 private state = 0;
    function plusOne() public {
        state = state + 1;
    }

    function getStates() public view returns (uint256) {
        return state;
    }

    function getFun() public view returns (string) {
        bytes4 memory bab = msg.sig;
        return string(bab);
    }
}