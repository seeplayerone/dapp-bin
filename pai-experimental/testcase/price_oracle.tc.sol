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

    function testInitAndGovernance() public {
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

    function testUpdateOverallPrice() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY);
        p1.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",7);
        tempBool = p1.callAddMember(paiDAO,p1,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p2,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p3,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p4,"BTCOracle");

        bool tempBool = p1.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //0
        tempBool = p2.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //1
        tempBool = p3.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //2
        tempBool = p4.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //3

        oracle.fly(50);
        tempBool = p1.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //4
        assertEq(oracle.getPrice(), RAY * 99/100);//5

        tempBool = p1.callUpdatePrice(oracle, RAY * 101/100);
        assertTrue(tempBool); //5
        tempBool = p2.callUpdatePrice(oracle, RAY * 102/100);
        assertTrue(tempBool); //6
        tempBool = p3.callUpdatePrice(oracle, RAY * 103/100);
        assertTrue(tempBool); //7
        tempBool = p4.callUpdatePrice(oracle, RAY * 98/100);
        assertTrue(tempBool); //8

        oracle.fly(50);
        tempBool = p1.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //9
        assertEq(oracle.getPrice(), RAY * 201/200);//10
    }

    function testSensitivity() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",9);

        FakePerson[5] memory p;
        for(uint i = 0; i < 5; i++) {
            p[i] = new FakePerson();
            admin.callAddMember(paiDAO,p[i],"BTCOracle");
        }

        for(uint j = 0; j < 10; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY * (101 + j)/100);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY );
            assertEq(oracle.getPrice(), RAY * (101 + j)/100);
        }

        for(j = 0; j < 10; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY * 10000);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY);
            assertEq(oracle.getPrice(), RAY * (101 + j) * 105/10000);
        }
    }
}