pragma solidity 0.4.25;

import "./simple_organization.sol";
import "../utils/ds-test.sol";
import "../utils/execution.sol";

contract FakeOrganization is SimpleOrganization, Execution {
    constructor(string organizationName, address[] _members)
        SimpleOrganization(organizationName, _members) 
        public 
        {
            templateName = "Fake-Template-Name-4-Test";
        }
}

contract CalledContract {
    uint public alpha = 0;
    uint public beta = 0;

    function doAlpha() public returns (uint) {
        return alpha++;
    }

    function doAlphaJoe(uint delta) public returns (uint) {
        alpha = alpha + delta;
        return alpha;
    }

    function doBeta() public payable returns (uint, uint) {
        alpha++;
        beta = beta + msg.value;
        return (alpha, beta);
    }

    function doBetaJoe(uint delta) public payable returns (uint, uint) {
        alpha = alpha + delta;
        beta = beta + msg.value;
        return (alpha, beta);
    }
}

contract OrganizationTest is DSTest, Execution {
    FakeOrganization crayfish;
    uint96 asset;

    function setup() public returns (uint32){
        crayfish = new FakeOrganization("crayfish",new address[](0));
        return crayfish.registerMe();
    }

    function testCreate() public {
        uint32 oid = setup();
        uint64 assetId = uint64(0) << 32 | uint64(oid);
        asset = uint96(assetId) << 32 | uint96(crayfish.assetIndex());
        crayfish.issueNewAsset("jack coin", "jc", "jack's first coin");
        assertEq(flow.balance(crayfish, asset), 1000000000);
    } 

    function testMint() public {
        testCreate();
        crayfish.issueMoreAsset(crayfish.assetIndex()-1);
        assertEq(flow.balance(crayfish, asset), 2000000000);
    }

    function testTransfer() public {
        testCreate();
        crayfish.transferAsset(0x668d5634afb9cfb064563b124bf6302ad78ed1cf40, asset, 200000000);
        assertEq(flow.balance(crayfish, asset), 800000000);
        assertEq(flow.balance(0x668d5634afb9cfb064563b124bf6302ad78ed1cf40, asset), 200000000);
    }

    function testExeAlpha() public {
        CalledContract jack = new CalledContract();

        execute(jack, jack.doAlpha.selector);
        assertEq(jack.alpha(), 1);
        execute(jack, "doAlpha()");
        assertEq(jack.alpha(), 2);
        execute(jack, jack.doAlphaJoe.selector, abi.encode(3));
        assertEq(jack.alpha(), 5);
        execute(jack, "doAlphaJoe(uint256)", abi.encode(5));
        assertEq(jack.alpha(), 10);
    }

    function testExeBeta() public {
        CalledContract jack = new CalledContract();
        testCreate();

        crayfish.execute(jack, jack.doBeta.selector, 100000000, asset);
        assertEq(jack.alpha(), 1);
        assertEq(jack.beta(), 100000000);
        crayfish.execute(jack, "doBeta()", 100000000, asset);
        assertEq(jack.alpha(), 2);
        assertEq(jack.beta(), 200000000);
        crayfish.execute(jack, jack.doBetaJoe.selector, abi.encode(3), 300000000, asset);
        assertEq(jack.alpha(), 5);
        assertEq(jack.beta(), 500000000);
        crayfish.execute(jack, "doBetaJoe(uint256)", abi.encode(5), 500000000, asset);
        assertEq(jack.alpha(), 10);
        assertEq(jack.beta(), 1000000000);
    }
}