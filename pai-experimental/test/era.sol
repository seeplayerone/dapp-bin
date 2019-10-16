pragma solidity 0.4.25;

import "../../library/template.sol";

contract ERA1 {
    event LOG(uint);
    function log() public {
        emit LOG(1);
    }
}

contract ERA2 {
    event LOG(uint);
    function log() public {
        emit LOG(2);
    }
}

contract TEST1 is ERA1, ERA2, Template {
    function test() public {
        log();
    }
}

contract TEST2 is ERA2, ERA1, Template {
    function test() public {
        log();
    }
}