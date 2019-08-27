pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/testnet-tutorial/tutorial.sol";
import "github.com/seeplayerone/dapp-bin/testnet-tutorial/test.sol";

contract NamedTutorial is Tutorial {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract TutorialTest is DSTest {
    NamedTutorial private tutorial;
    address private dest = 0x668eb397ce8ccc9caec9fec1b019a31f931725ca94;

    uint private SATOSHI = 10**8;

    function test() public returns (bool) {
        tutorial = new NamedTutorial();

        uint assettype = tutorial.mint(10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);

        tutorial.mint(10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 20 * SATOSHI);

        tutorial.transfer(dest, 10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);
        assertEq(tutorial.checkTotalSupply(), 20 * SATOSHI);

        tutorial.burn.value(10 * SATOSHI, assettype)();
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);
        assertEq(tutorial.checkTotalSupply(), 10 * SATOSHI);

        return true;
    }

    function testVoid() public returns (bool) {
        return true;
    }
}