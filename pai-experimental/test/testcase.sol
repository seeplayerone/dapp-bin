pragma solidity 0.4.25;

contract TestCase {
    event LOG(uint);

    function testOne() public returns (bool){
        emit LOG(888);
        return true;
    }
    
}