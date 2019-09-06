pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/pai-experimental/mathPI.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/testPI.sol";




contract TestMath is DSTest, MathPI {
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;

    function testLog2() public {
        uint baseInterestRate = 1000000005781380000000000000;
        uint cutDown = RAY / 1000;
        uint adjustedInterestRate = optimalExp(generalLog(rpow(baseInterestRate, 1 years) - cutDown)/ 1 years);
        assertEq(adjustedInterestRate,0);
        // assertEq(generalLog(RAY * 11/10),0);
        // assertEq(generalLog(RAY * 12/10),0);
        // assertEq(generalLog(RAY * 13/10),0);
        // assertEq(generalLog(RAY * 14/10),0);
        // assertEq(generalLog(RAY * 15/10),0);
        // assertEq(generalLog(RAY * 16/10),0);
        // assertEq(generalLog(RAY * 17/10),0);
        // assertEq(generalLog(RAY * 18/10),0);
        // assertEq(generalLog(RAY * 19/10),0);

        // assertEq(generalLog(RAY * 2), 888);
        // assertEq(generalLog(RAY * 4), 888);
        // assertEq(generalLog(RAY * 8), 888);
        // assertEq(generalLog(RAY * 16), 888);
        // assertEq(generalLog(RAY * 32), 888);

    }
}