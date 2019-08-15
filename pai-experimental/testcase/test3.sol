pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract test is Template {
    uint256 private state = 0;
    uint private ASSET_BTC = 0;
    function plusOne() public {
        state = state + 1;
        msg.sender.transfer(100000000, ASSET_BTC);
    }

    function() public payable {}

    function getStates() public view returns (uint256) {
        return state;
    }
}