pragma solidity 0.4.25;

import "../../library/template.sol";
import "../bank_issuer.sol";
import "./ds_test_v2.sol";
import "../pis_main.sol";
import "../testcase/testPrepare.sol";

contract TestBankIssuer is Template, DSTest {
    function() public payable {}
    uint96 ASSET_A;
    uint96 ASSET_B;
    function testAll() public {
        FakePaiDaoNoGovernance paiDAO = new FakePaiDaoNoGovernance("PAIDAO");
        paiDAO.init();
        FakeBankIssuer issuer = new FakeBankIssuer("BANKISSUER",paiDAO);
        issuer.init();
        issuer.createAsset("aa","bb","cc",1);
        issuer.createAsset("bbb","ccc","ddd",2);

        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();

        bool exist;
        string memory name;
        string memory symbol;
        string memory des;
        uint supply;
        Registry registry = Registry(0x630000000000000000000000000000000000000065);
        (exist,name,symbol,des,supply,) = registry.getAssetInfoByAssetId(issuer.organizationId(),1);
        assertTrue(exist);
        assertEq(name,"aa");
        assertEq(symbol,"bb");
        assertEq(des,"cc");
        assertEq(supply,0);
        ASSET_A = issuer.AssetGlobalId(1);
        (exist,name,symbol,des,supply,) = registry.getAssetInfoByAssetId(issuer.organizationId(),2);
        assertTrue(exist);
        assertEq(name,"bbb");
        assertEq(symbol,"ccc");
        assertEq(des,"ddd");
        assertEq(supply,0);
        ASSET_B = issuer.AssetGlobalId(2);

        issuer.mint(1,1000,p1);
        issuer.mint(2,2000,p2);
        assertEq(flow.balance(p1,ASSET_A),1000);
        assertEq(flow.balance(p2,ASSET_B),2000);

    }
}