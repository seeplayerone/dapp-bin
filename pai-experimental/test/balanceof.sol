pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";

contract BalanceOf is Template {
    uint amount;
    uint assettype;

    address private hole = 0x660000000000000000000000000000000000000000;    

    event Balance(uint);

    function test() public payable {
        amount = msg.value;

        emit Balance(amount);
        emit Balance(flow.balance(this, msg.assettype));

        hole.transfer(msg.value/2, msg.assettype);
        amount = msg.value/2;

        emit Balance(amount);
        emit Balance(flow.balance(this, msg.assettype));        
    }
}