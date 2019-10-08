pragma solidity 0.4.25;

contract testForLoop {
    uint state = 0;
    function test() public returns(uint) {
        uint a = 3;
        uint b = 4;
        for(uint i = b; i < a; i++) {
            state = state + 1;
        }
        return state;
    }
}