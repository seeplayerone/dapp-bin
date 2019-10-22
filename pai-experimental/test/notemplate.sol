pragma solidity 0.4.25;

import "./balanceof2.sol";
import "../../library/template.sol";

//import "./balanceof2.sol";

contract NoTemplate is Template {
    function test() public returns (uint, uint){
        BalanceOf bo = new BalanceOf();
        bo.addDebt(666);
        return bo.getData();
    }
}

