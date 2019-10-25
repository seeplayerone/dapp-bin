pragma solidity 0.4.25;

import "./simple_organization.sol";
import "../utils/ds-test.sol";
import "../utils/execution.sol";

interface RegistryInterface {
    function getAssetInfoByAssetId(uint32 organizationId, uint32 assetIndex) external view returns(bool, string, string, string, uint, uint[]);
}

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
    RegistryInterface registry;

    function() public payable {}

    function setup() public returns (uint32){
        registry = RegistryInterface(0x630000000000000000000000000000000000000065);
        crayfish = new FakeOrganization("crayfish",new address[](0));
        return crayfish.registerMe();
    }

    function testCreate() public returns (uint32) {
        uint32 oid = setup();
        uint64 assetId = uint64(0) << 32 | uint64(oid);
        asset = uint96(assetId) << 32 | uint96(crayfish.assetIndex());
        crayfish.issueNewAsset("jack coin", "jc", "jack's first coin");
        assertEq(flow.balance(crayfish, asset), 1000000000);

        (,,,,uint totalsupply,) = registry.getAssetInfoByAssetId(oid, crayfish.assetIndex()-1);
        assertEq(totalsupply, 1000000000);

        return oid;
    } 

    function testMint() public {
        uint32 oid = testCreate();
        crayfish.issueMoreAsset(crayfish.assetIndex()-1);
        assertEq(flow.balance(crayfish, asset), 2000000000);

        (,,,,uint totalsupply,) = registry.getAssetInfoByAssetId(oid, crayfish.assetIndex()-1);
        assertEq(totalsupply, 2000000000);
    }

    function testTransfer() public returns (uint32){
        uint32 oid = testCreate();
        crayfish.transferAsset(this, asset, 200000000);
        assertEq(flow.balance(crayfish, asset), 800000000);
        assertEq(flow.balance(this, asset), 200000000);
        return oid;
    }

    function testBurn() public payable {
        uint32 oid = testTransfer();
        crayfish.burnAsset.value(100000000,asset)();

        (,,,,uint totalsupply,) = registry.getAssetInfoByAssetId(oid, crayfish.assetIndex()-1);
        assertEq(totalsupply, 900000000);
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