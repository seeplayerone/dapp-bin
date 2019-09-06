pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";

contract Value1 is Template {
    Value2 value2;
    constructor(address value2Address) public {
        value2 = Value2(value2Address);
    }
    function give() public payable {
        value2.accept.value(msg.value);
    }
}

contract Value2 is Template {
    event LOG(uint, uint);
    function accept() public payable {
        emit LOG(msg.value, msg.assettype);
    }
}