pragma solidity 0.4.25;

import "./simple_organization.sol";
import "../utils/ds-test.sol";

contract FakeOrganization is SimpleOrganization {
    constructor(string organizationName, address[] _members)
        SimpleOrganization(organizationName, _members) 
        public 
        {
            templateName = "Fake-Template-Name-4-Test";
        }
}

contract OrganizationTest is DSTest{
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
}