pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract test is Template {
    uint a = 1;
    uint b = 2;
    uint test1 = 0;
    uint test2 = 0;
    uint test3 = 0;
    function setParam1() public {
        (test1,test2) = getAB();
    }
    function setParam2() public {
        (test3,) = getAB();
    }

    function setParam3() public {
        (,test3) = getAB();
    }

    function setZero() public {
        test1 = 0;
        test2 = 0;
        test3 = 0;
    }

    function getAB() public view returns (uint,uint) {
        return (a,b);
    }

    function getTestNumber() public view returns (uint,uint,uint) {
        return (test1,test2,test3);
    }

}