pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/test/org1.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/test/org2.sol";


contract FakeORG1 is ORG1 {
    constructor() public {
        templateName = "ORG1";
    }
}

contract FakeORG2 is ORG2 {
    constructor() public {
        templateName = "ORG2";
    }
}

contract TestInterface is Template {
    function init() public {
        FakeORG1 o1 = new FakeORG1();
        o1.init("o1");
        FakeORG2 o2 = new FakeORG2();
        o2.init("o2");
    }
}