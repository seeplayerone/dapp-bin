pragma solidity 0.4.25;

//import "../SafeMath.sol";
//import "../acl.sol";
//import "../template.sol";

import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";
import "github.com/seeplayerone/dapp-bin/library/acl.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";


contract AsiRoll is ACL, Template {

    string constant DEPOSIT = "DEPOSIT";

    constructor() public payable {
        configureFunctionAddressInternal(DEPOSIT, msg.sender, OpMode.Add);
    }

    function() public payable{}

    function deposit() public payable authFunctionHash(DEPOSIT) {
    }

    function roll() public payable {
        uint asset = msg.assettype;
        uint value = msg.value;
        if(rollInternal() == 0) {
            msg.sender.transfer(SafeMath.mul(value, 2), asset);
        }
    }

    function rollInternal() internal view returns (uint){
        uint seed = block.timestamp;
        return SafeMath.mod(seed, 2);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }


}