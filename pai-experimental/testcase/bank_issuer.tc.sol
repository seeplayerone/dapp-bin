pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/bank_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";



contract TestBankIssuer is Template, DSTest {
    function() public payable {}

    function testCreateAsset() public {
        FakePaiDaoNoGovernance paiDAO = new FakePaiDaoNoGovernance("PAIDAO");
        paiDAO.init();
        FakeBankIssuer issuer = new FakeBankIssuer("BANKISSUER",paiDAO);
        issuer.init();

        issuer.createAsset("aa","bb","cc");
        //issuer.createAsset("bb","cc","dd");

        bool exist;
        string name;
        string symbol;
        string des;
        uint32 id;
        uint supply;
        (exist,name,symbol,des,id,supply) = getAssetInfo(1);
        assertTrue(exist);
        assertEq(id,0);
        assertEq(supply,0);

    }
}