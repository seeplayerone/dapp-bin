pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../price_oracle.sol";
// import "../3rd/test.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";


contract PriceOracleTest is Template, DSTest,DSMath {
    TimefliesOracle private oracle;

    function testSetup() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY);

        assertEq(oracle.getPrice(), RAY);//0
        bool tempBool = p1.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",0);
        assertTrue(tempBool); //1
        tempBool = p2.callUpdatePrice(oracle,2*RAY);
        assertTrue(!tempBool); //2
        tempBool = p1.callAddMember(paiDAO,p2,"BTCOracle");
        assertTrue(tempBool); //3
        tempBool = p2.callUpdatePrice(oracle,2*RAY);
        assertTrue(tempBool); //4
    }

    function 
}