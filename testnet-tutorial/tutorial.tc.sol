pragma solidity 0.4.25;

<<<<<<< HEAD
import "../testnet-tutorial/tutorial.sol";
import "../testnet-tutorial/test.sol";
=======
import "./tutorial.sol";
import "./test.sol";
>>>>>>> 89ee487a1200d31158e9866e60161e93d435b721

/**
    @dev we recommend "test driven development" paradigm for contract developing
     developers should write thorough testcases before submit a TEMPLATE on asimov

     test case execution using asimov IDE tool is not state perserving
     and each test case is executed on `zero state` (the chain state of the moment you execute)
*/

/**
    @dev in test mode, we bypass the TEMPLATE precedure for convenience 
     as a result, we need to create a wrapper target contract with a fake template name
     if we need to register and issue assets (no need for other cases)
*/
contract NamedTutorial is Tutorial {
<<<<<<< HEAD
    constructor(string _name) 
        Tutorial(_name)
        public 
    {
=======
    constructor() 
        Tutorial("Fake-Name-For-Test")
        public {
>>>>>>> 89ee487a1200d31158e9866e60161e93d435b721
        templateName = "Fake-Template-Name-For-Test";
    }
}

/**
    @dev we use DSTest for assertion, which is an excellent lib provided by https://dapp.tools/
*/
contract TutorialTest is DSTest {
    NamedTutorial private tutorial;

    uint private SATOSHI = 10**8;

    /// the test contract is payable because it needs to receive assets
    function() public payable {

    }

    function test() public returns (bool) {
        /// @dev create contract INSTANCE from scratch is only avaiable in test mode
        tutorial = new NamedTutorial("sb");

        uint assettype = tutorial.mint(10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);

        tutorial.mint(10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 20 * SATOSHI);

        tutorial.transfer(this, 10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);
        assertEq(tutorial.checkTotalSupply(), 20 * SATOSHI);

        tutorial.burn.value(10 * SATOSHI, assettype)();
        assertEq(tutorial.checkBalance(), 10 * SATOSHI);
        assertEq(tutorial.checkTotalSupply(), 10 * SATOSHI);

        tutorial.callValue(this, 10 * SATOSHI);
        assertEq(tutorial.checkBalance(), 0);
        assertEq(tutorial.checkTotalSupply(), 10 * SATOSHI);

        return true;
    }
}