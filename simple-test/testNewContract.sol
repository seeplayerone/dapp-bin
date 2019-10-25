pragma solidity 0.4.25;

import "./testBalance2.sol";
import "../library/template.sol";


contract NoTemplate is Template {
    function test() public returns (uint, uint){
        TestBalance bo = new TestBalance();
        bo.addDebt(666);
        return bo.getData();
    }
}

