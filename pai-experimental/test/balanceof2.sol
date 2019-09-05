pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract BalanceOf is Template {

    uint debt;

    address private hole = 0x660000000000000000000000000000000000000000;    

    function addDebt(uint x) public {
        debt = debt + x;
        cancelDebt();
    }

    function addDeposit() public payable {
        cancelDebt();
    }
    
    function cancelDebt() internal {
        if(debt == 0 || flow.balance(this, 0) == 0) {
            return;
        }

        uint256 amount = debt > flow.balance(this, 0) ? flow.balance(this, 0) : debt;
        debt = debt - amount;

        hole.transfer(amount, 0);        
    }

    function getData() public returns (uint, uint) {
        return (debt, flow.balance(this, 0));
    }
}