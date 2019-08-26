pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/testnet-tutorial/tutorial.sol";
import "github.com/seeplayerone/dapp-bin/testnet-tutorial/test.sol";

contract NamedTutorial is Tutorial {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract PAIIssuerTest {
    NamedTutorial private tutorial;
    address private dest = 0x668eb397ce8ccc9caec9fec1b019a31f931725ca94;

    function test() public {
        tutorial = new NamedTutorial();

        uint assettype = tutorial.mint(10 * 10**8);
        AssertEq(tutorial.checkBalance(), 10 * 10**8);

        tutorial.mint(10 * 10**8);
        AssertEq(tutorial.checkBalance(), 20 * 10**8);

        tutorial.transfer(dest, 10 * 10**8);
        AssertEq(tutorial.checkBalance(), 10 * 10**8);
        AssertEq(tutorial.totalSupply(), 20 * 10**8);

        tutorial.burn.value(10 * 10**8, assettype);
        AssertEq(tutorial.checkBalance(), 10 * 10**8);
        AssertEq(tutorial.totalSupply(), 10 * 10**8);
    }
}