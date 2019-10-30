pragma solidity 0.4.25;

import "../../library/template.sol";
import "../price_oracle.sol";
import "../testPI.sol";
import "./testPrepare.sol";


contract PriceOracleTest is Template, DSTest,DSMath {
    TimefliesOracle private oracle;

    function testInitAndGovernance() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);

        assertEq(oracle.getPrice(), RAY);//0
        bool tempBool = p1.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",0,false);
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
        
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        p1.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",7,false);
        bool tempBool = p1.callAddMember(paiDAO,p1,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p2,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p3,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p4,"BTCOracle");

        tempBool = p1.callUpdatePrice(oracle, RAY * 99/100);
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
        assertTrue(tempBool); //6
        tempBool = p2.callUpdatePrice(oracle, RAY * 102/100);
        assertTrue(tempBool); //7
        tempBool = p3.callUpdatePrice(oracle, RAY * 103/100);
        assertTrue(tempBool); //8
        tempBool = p4.callUpdatePrice(oracle, RAY * 98/100);
        assertTrue(tempBool); //9

        oracle.fly(50);
        tempBool = p1.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //10
        assertEq(oracle.getPrice(), RAY * 201/200);//11

        tempBool = p1.callUpdatePrice(oracle, RAY * 97/100);
        assertTrue(tempBool); //12
        tempBool = p2.callUpdatePrice(oracle, RAY * 98/100);
        assertTrue(tempBool); //13
        tempBool = p3.callUpdatePrice(oracle, RAY * 99/100);
        assertTrue(tempBool); //14
        tempBool = p4.callUpdatePrice(oracle, RAY * 98/100);
        assertTrue(tempBool); //15
        tempBool = p1.callUpdatePrice(oracle, RAY * 102/100);
        assertTrue(tempBool); //16
        tempBool = p2.callUpdatePrice(oracle, RAY * 104/100);
        assertTrue(tempBool); //17
        tempBool = p3.callUpdatePrice(oracle, RAY * 103/100);
        assertTrue(tempBool); //18
        tempBool = p4.callUpdatePrice(oracle, RAY * 102/100);
        assertTrue(tempBool); //19

        oracle.fly(50);
        tempBool = p1.callUpdatePrice(oracle, RAY * 102/100);
        assertTrue(tempBool); //20
        assertEq(oracle.getPrice(), RAY * 205/200);//21
    }

    function testSensitivity() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",9,false);

        FakePerson[5] memory p;
        for(uint i = 0; i < 5; i++) {
            p[i] = new FakePerson();
            admin.callAddMember(paiDAO,p[i],"BTCOracle");
        }

        for(uint j = 0; j < 9; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY * (101 + j)/100);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY);
            assertEq(oracle.getPrice(), RAY * (101 + j)/100);
        }

        for(j = 0; j < 10; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY * 10000);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY);
            assertEq(oracle.getPrice(), RAY * (100 + j) * 105/10000);
        }
    }

    function testSensitivity2() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",9,false);

        FakePerson[5] memory p;
        for(uint i = 0; i < 5; i++) {
            p[i] = new FakePerson();
            admin.callAddMember(paiDAO,p[i],"BTCOracle");
        }

        for(uint j = 0; j < 9; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY * (99 - j)/100);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY);
            assertEq(oracle.getPrice(), RAY * (99 - j)/100);
        }

        for(j = 0; j < 10; j++) {
            for(i = 0; i < 5; i++) {
                p[i].callUpdatePrice(oracle, RAY / 10000);
            }
            oracle.fly(30);
            p[1].callUpdatePrice(oracle, RAY);
            assertEq(oracle.getPrice(), RAY * (100 - j) * 95/10000);
        }
    }

    function testUpdateFail() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",9,false);
        admin.callCreateNewRole(paiDAO,"DirVote@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,admin,"DirVote@STCoin");

        FakePerson[5] memory p;
        for(uint i = 0; i < 5; i++) {
            p[i] = new FakePerson();
            admin.callAddMember(paiDAO,p[i],"BTCOracle");
        }

        bool tempBool = admin.callModifyEffectivePriceNumber(oracle,5);
        assertTrue(tempBool);

        p[0].callUpdatePrice(oracle, RAY * 101 / 100);
        p[1].callUpdatePrice(oracle, RAY * 101 / 100);
        p[2].callUpdatePrice(oracle, RAY * 101 / 100);
        p[3].callUpdatePrice(oracle, RAY * 101 / 100);
        oracle.fly(30);
        p[0].callUpdatePrice(oracle, RAY * 101 / 100);
        assertEq(oracle.getPrice(), RAY);
        p[4].callUpdatePrice(oracle, RAY * 101 / 100);
        oracle.fly(30);
        p[0].callUpdatePrice(oracle, RAY * 101 / 100);
        assertEq(oracle.getPrice(), RAY * 101 / 100);

        tempBool = p[0].callUpdatePrice(oracle, 2 ** 220);
        assertTrue(!tempBool);
    }

    function testDisableEnable() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",9,false);
        admin.callCreateNewRole(paiDAO,"OracleManager@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"DirVote@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,admin,"DirVote@STCoin");
        admin.callModifyDisableOracleLimit(oracle,uint8(2));

        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson manager = new FakePerson();

        bool tempBool = p1.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(!tempBool);//0
        tempBool = admin.callAddMember(paiDAO,p1,"BTCOracle");
        assertTrue(tempBool);//1
        tempBool = p1.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(tempBool);//2

        tempBool = manager.callDisableOne(oracle, p1);
        assertTrue(!tempBool);//3
        tempBool = admin.callAddMember(paiDAO,manager,"OracleManager@STCoin");
        assertTrue(tempBool);//4
        tempBool = manager.callDisableOne(oracle, p1);
        assertTrue(tempBool);//5
        tempBool = p1.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(!tempBool);//6

        tempBool = admin.callAddMember(paiDAO,p2,"BTCOracle");
        assertTrue(tempBool);//7
        tempBool = p2.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(tempBool);//8
        tempBool = manager.callDisableOne(oracle, p2);
        assertTrue(tempBool);//9
        tempBool = p2.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(!tempBool);//10
        assertEq(oracle.disabledNumber(),2);//11
        assertTrue(oracle.disabled(p1));//12
        assertTrue(oracle.disabled(p2));//13

        tempBool = admin.callAddMember(paiDAO,p3,"BTCOracle");
        assertTrue(tempBool);//14
        tempBool = manager.callDisableOne(oracle, p3);
        assertTrue(!tempBool);//15
        tempBool = manager.callEnableOne(oracle, p1);
        assertTrue(tempBool);//16
        assertTrue(!oracle.disabled(p1));//17
        assertEq(oracle.disabledNumber(),1);//18
        tempBool = p1.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(tempBool);//19
        tempBool = manager.callDisableOne(oracle, p3);
        assertTrue(tempBool);//20
        assertTrue(oracle.disabled(p3));//21
        assertEq(oracle.disabledNumber(),2);//22
        tempBool = p3.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(!tempBool);//23

        tempBool = admin.callEmptyDisabledOracle(oracle);
        assertTrue(tempBool);//24
        assertEq(oracle.disabledNumber(),0);//25
        tempBool = p2.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(tempBool);//26
        tempBool = p3.callUpdatePrice(oracle, RAY * 101 / 100);
        assertTrue(tempBool);//27
    }

    function testSetting() public {
        FakePaiDao paiDAO;
        FakePerson admin = new FakePerson();
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        admin.callCreateNewRole(paiDAO,"DirVote@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,p1,"DirVote@STCoin");

        bool tempBool = p2.callModifyUpdateInterval(oracle, 100);
        assertTrue(!tempBool);
        tempBool = p2.callModifySensitivityTime(oracle, 500);
        assertTrue(!tempBool);
        tempBool = p2.callModifySensitivityRate(oracle, RAY / 10);
        assertTrue(!tempBool);

        tempBool = p1.callModifyUpdateInterval(oracle, 100);
        assertTrue(tempBool);
        assertEq(oracle.updateInterval(),100);
        p1.callModifyUpdateInterval(oracle, 200);
        assertEq(oracle.updateInterval(),200);
        tempBool = p1.callModifyUpdateInterval(oracle, 0);
        assertTrue(!tempBool);

        tempBool = p1.callModifySensitivityTime(oracle, 500);
        assertTrue(tempBool);
        assertEq(oracle.sensitivityTime(),500);
        tempBool = p1.callModifySensitivityTime(oracle, 1000);
        assertTrue(tempBool);
        assertEq(oracle.sensitivityTime(),1000);
        tempBool = p1.callModifySensitivityTime(oracle, 200);
        assertTrue(!tempBool);
        p1.callModifyUpdateInterval(oracle, 100);
        tempBool = p1.callModifySensitivityTime(oracle, 100);
        assertTrue(!tempBool);

        tempBool = p1.callModifySensitivityRate(oracle, RAY / 10);
        assertTrue(tempBool);
        assertEq(oracle.sensitivityRate(), RAY / 10);
        p1.callModifySensitivityRate(oracle, RAY / 20);
        assertEq(oracle.sensitivityRate(), RAY / 20);
        tempBool = p1.callModifySensitivityRate(oracle, RAY / 10000);
        assertTrue(!tempBool);
    }

    function testLongHistoryFunc() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,0);
        p1.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",7,false);
        bool tempBool = p1.callAddMember(paiDAO,p1,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p2,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p3,"BTCOracle");
        tempBool = p1.callAddMember(paiDAO,p4,"BTCOracle");

        for(uint i = 0 ; i <= 1000; i++) {
            tempBool = p1.callUpdatePrice(oracle, RAY * (1000+i)/1000);
            assertTrue(tempBool); //0
            tempBool = p2.callUpdatePrice(oracle, RAY * (1000+i)/1000);
            assertTrue(tempBool); //1
            tempBool = p3.callUpdatePrice(oracle, RAY * (1000+i)/1000);
            assertTrue(tempBool); //2
            tempBool = p4.callUpdatePrice(oracle, RAY * (1000+i)/1000);
            assertTrue(tempBool); //3

            oracle.fly(50);
            tempBool = p1.callUpdatePrice(oracle, RAY * (1000+i)/1000);
            assertTrue(tempBool); //4
            assertEq(oracle.getPrice(), RAY * (1000+i)/1000);//5
        }

    }
}