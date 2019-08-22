pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract testA is Template {
    mapping(uint => uint) public testmap;

    function init() public {
        testmap[1] = 3;
        testmap[2] = 5;
    }
}

contract testB is Template {
    testA A;

    function testMapping() public view returns (uint){
        A = new testA();
        A.init();
        return A.testmap(1);
    }

}