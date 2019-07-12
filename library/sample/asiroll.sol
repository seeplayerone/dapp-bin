pragma solidity 0.4.25;

//import "../SafeMath.sol";
//import "../acl.sol";
//import "../template.sol";

import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";
import "github.com/seeplayerone/dapp-bin/library/acl.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";


contract AsiRoll is ACL, Template {

    string constant FALLBACK = "FALLBACK";
    string constant DEPOSIT = "DEPOSIT";

    uint private balance;
    uint private roll;
    uint private win;

    constructor() public payable {
        balance = SafeMath.add(balance, msg.value);
        configureFunctionAddressInternal(FALLBACK, msg.sender, OpMode.Add);
        configureFunctionAddressInternal(DEPOSIT, msg.sender, OpMode.Add);
    }

    function() public payable authFunctionHash(FALLBACK) {
        balance = SafeMath.add(balance, msg.value);
    }

    function deposit() public payable authFunctionHash(DEPOSIT) {
        balance = SafeMath.add(balance, msg.value);
    }

    function play(uint lucky) public payable {
        require(lucky > 0);
        require(lucky < 100);
        uint asset = msg.assettype;
        uint value = msg.value;

        roll = random();

        /// u win
        if(lucky >= roll) {
            win = SafeMath.div(SafeMath.mul(value, 100), lucky);
            msg.sender.transfer(win, asset);
            balance = SafeMath.sub(balance, win);
        } else {
            win = 0;
        }
    }

    function random() private view returns (uint) {
        return SafeMath.mod(uint(keccak256(block.timestamp)),100);
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function getLastRoll() public view returns (uint) {
        return roll;
    }

    function getLastWin() public view returns (uint) {
        return win;
    }


}