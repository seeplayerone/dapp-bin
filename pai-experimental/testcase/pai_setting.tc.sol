pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../price_oracle.sol";
// import "../3rd/test.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";


contract GlobalSettingTest is Template, DSTest, DSMath {
    
    function testAll() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();

        paiDAO = FakePaiDao(admin.createPAIDAONoGovernance("PAIDAO"));
        paiDAO.init();
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0);
        admin.callAddMember(paiDAO,p1,"DIRECTORVOTE");
        Setting setting = new Setting(paiDAO);

        bool tempBool = p2.callUpdateLendingRate(setting, RAY/10);
        assertTrue(!tempBool);
        assertEq(setting.lendingInterestRate(),RAY/10);
        tempBool = p1.callUpdateLendingRate(setting, RAY/10);
        assertTrue(tempBool);
        assertEq(setting.lendingInterestRate(),RAY/10);



    }
}