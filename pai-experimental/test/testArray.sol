pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract FakePerson is Template {
    function() public payable {}
}

contract testArray {
    function lala() public returns (uint) {
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        FakePerson p5 = new FakePerson();
        address[] list1;
        list1.push(p2);
        list1.push(p3);
        address[] list2;
        list2.push(p2);
        list2.push(p3);
        list2.push(p4);
        list2.push(p5);
        return list2.length;
    }
}