pragma solidity 0.4.25;

contract TestCase {
    event LOG(uint);

    function testOne() public returns (bool) {
        emit LOG(888);
        return true;
    }

    function testThree() public pure returns (bool) {
        require(1 > 2);
    }

    function testTwo() public returns (bool) {
        emit LOG(666);
        return false;
    }    
}