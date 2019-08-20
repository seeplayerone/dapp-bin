pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract test is Template {
    uint256 public state = 0;
    function plusOne() public payable {
        state = state + 1;
    }

    function getStates() public view returns (uint256) {
        return state;
    }

}

contract test2 is Template {
    uint256 private st = 0;
    function getFrom(address _addr) public {
        st = test(_addr).state();
    }

    function getStates() public view returns (uint256) {
        return st;
    }
}