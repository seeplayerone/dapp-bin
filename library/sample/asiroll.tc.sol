pragma solidity 0.4.25;

import "./asiroll.sol";

///@dev TO BE TEST

contract AsiRollTest {
    AsiRoll tool;

    event Logs(uint256 balance, uint256 roll, uint256 win, uint256 lucky);

    function() public payable {}

    function setup() public {
        tool = new AsiRoll();

        tool.deposit.value(100*10**8, 0x000000000000)();
        emit Logs(tool.getBalance(), tool.getLastRoll(), tool.getLastWin(), tool.getLastLucky());
    }

    function testPlay() public {
        setup();
        
        tool.play.value(10**8,0x000000000000)(20);
        emit Logs(tool.getBalance(), tool.getLastRoll(), tool.getLastWin(), tool.getLastLucky());

        tool.play.value(10**8,0x000000000000)(40);
        emit Logs(tool.getBalance(), tool.getLastRoll(), tool.getLastWin(), tool.getLastLucky());

        tool.play.value(10**8,0x000000000000)(60);
        emit Logs(tool.getBalance(), tool.getLastRoll(), tool.getLastWin(), tool.getLastLucky());

        tool.play.value(10**8,0x000000000000)(80);
        emit Logs(tool.getBalance(), tool.getLastRoll(), tool.getLastWin(), tool.getLastLucky());
    }
}