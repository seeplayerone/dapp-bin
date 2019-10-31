pragma solidity 0.4.25;

import "./testPrepare.sol";

contract TestBase is Template, DSTest, DSMath {
    TimefliesCDP internal cdp;
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
    TimefliesOracle internal oracle2;
    FakePAIIssuer internal paiIssuer;
    FakeBTCIssuer internal btcIssuer;
    FakePerson internal admin;
    FakePerson internal p1;
    FakePerson internal p2;
    FakePaiDao internal paiDAO;
    Setting internal setting;
    Finance internal finance;

    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PAI;
    uint96 internal ASSET_PIS;

    function() public payable {

    }

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());

        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY,ASSET_BTC);
        oracle2  = new TimefliesOracle("BTCOracle",paiDAO,RAY,ASSET_PIS);
        admin.callCreateNewRole(paiDAO,"Liqudator@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",3,false);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"Settlement@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"BTCCDP","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"DirVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"50%DemPreVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"100%DemPreVote@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"50%Demonstration@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"100%Demonstration@STCoin","ADMIN",0,false);
        admin.callCreateNewRole(paiDAO,"DirPisVote","ADMIN",0,false);
        admin.callAddMember(paiDAO,admin,"BTCOracle");
        admin.callAddMember(paiDAO,p1,"BTCOracle");
        admin.callAddMember(paiDAO,p2,"BTCOracle");
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callAddMember(paiDAO,admin,"Settlement@STCoin");
        admin.callAddMember(paiDAO,admin,"DirVote@STCoin");
        admin.callAddMember(paiDAO,admin,"50%DemPreVote@STCoin");
        admin.callAddMember(paiDAO,admin,"100%DemPreVote@STCoin");
        admin.callAddMember(paiDAO,admin,"50%Demonstration@STCoin");
        admin.callAddMember(paiDAO,admin,"100%Demonstration@STCoin");
        admin.callAddMember(paiDAO,admin,"BTCCDP");
        admin.callAddMember(paiDAO,admin,"DirPisVote");
        admin.callModifyEffectivePriceNumber(oracle,3);

        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();

        setting = new Setting(paiDAO);
        finance = new Finance(paiDAO,paiIssuer,setting,oracle2);
        liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        cdp = new TimefliesCDP(paiDAO,paiIssuer,oracle,liquidator,setting,finance,100000000000);
        admin.callCreateNewRole(paiDAO,"Minter@STCoin","ADMIN",0,false);
        admin.callAddMember(paiDAO,cdp,"Minter@STCoin");
        admin.callAddMember(paiDAO,cdp,"BTCCDP");

        btcIssuer.mint(100000000000, p1);
        btcIssuer.mint(100000000000, p2);
        btcIssuer.mint(100000000000, this);
        admin.callMint(paiIssuer,100000000000,p1);
        admin.callMint(paiIssuer,100000000000,p2);
        admin.callMint(paiIssuer,100000000000,this);
    }

    function setupTest() public {
        setup();
        assertEq(oracle.getPrice(), RAY);
        admin.callUpdatePrice(oracle, RAY * 99/100);
        p1.callUpdatePrice(oracle, RAY * 99/100);
        p2.callUpdatePrice(oracle, RAY * 99/100);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 99/100);
        assertEq(oracle.getPrice(), RAY * 99/100);

    }
}

contract SettingTest is TestBase {
    function testUpdateBaseInterestRate() public {
        setup();
        admin.callUpdateLendingRate(setting, RAY * 202 / 1000);
        cdp.updateBaseInterestRate();
        assertEq(cdp.annualizedInterestRate(),RAY / 5);
        assertEq(cdp.secondInterestRate(),1000000005781378656804591713);
        //exp(log(1.2)/365/86400)*10^27 = 1000000005781378662058164224
        admin.callUpdateLendingRate(setting, RAY * 102 / 1000);
        assertEq(cdp.annualizedInterestRate(),RAY / 5);
        assertEq(cdp.secondInterestRate(),1000000005781378656804591713);
        cdp.updateBaseInterestRate();
        assertEq(cdp.annualizedInterestRate(),RAY / 10);
        assertEq(cdp.secondInterestRate(),1000000003022265980097387650);
        //exp(log(1.1)/365/86400)*10^27 = 1000000003022265970012364960
    }

    function testUpdateBaseInterestRateAdjustment() public {
        setup();
        admin.callUpdateLendingRate(setting, RAY * 202 / 1000);
        cdp.updateBaseInterestRate();
        assertEq(cdp.annualizedInterestRate(),RAY / 5);
        assertEq(cdp.secondInterestRate(),1000000005781378656804591713);
        admin.callUpdateBaseRateAdj(cdp,-int(RAY / 10));
        assertEq(cdp.annualizedInterestRate(),RAY / 10);
        assertEq(cdp.secondInterestRate(),1000000003022265980097387650);
    }

    function testUpdateRateAdj() public {
        setup();
        assertEq(cdp.rateAdj(0), -int(RAY * 2 / 1000));
        assertEq(cdp.rateAdj(1), -int(RAY * 4 / 1000));
        assertEq(cdp.rateAdj(2), -int(RAY * 6 / 1000));
        assertEq(cdp.rateAdj(3), -int(RAY * 8 / 1000));
        assertEq(cdp.rateAdj(4), -int(RAY * 10 / 1000));
        assertEq(cdp.rateAdj(5), -int(RAY * 12 / 1000));
        assertEq(cdp.rateAdj(6), 0);
        assertEq(cdp.rateAdj(7), 0);
        assertEq(cdp.rateAdj(8), 0);
        assertEq(cdp.rateAdj(9), 0);
        assertEq(cdp.rateAdj(10), 0);
        bool tempBool = p1.callUpdateRateAdj(cdp,1,int(RAY * 2 / 1000));
        assertTrue(!tempBool);
        for(uint8 i = 0 ; i <= 10; i++) {
            admin.callUpdateRateAdj(cdp,i,int(RAY * 1 / 1000));
            assertEq(cdp.rateAdj(i), int(RAY * 1 / 1000));
        }
        tempBool = admin.callUpdateRateAdj(cdp,11,int(RAY * 2 / 1000));
        assertTrue(!tempBool);
    }

    function testUpdateTerm() public {
        setup();
        assertEq(cdp.term(1), 30 * 86400);
        assertEq(cdp.term(2), 60 * 86400);
        assertEq(cdp.term(3), 90 * 86400);
        assertEq(cdp.term(4), 180 * 86400);
        assertEq(cdp.term(5), 360 * 86400);
        assertEq(cdp.term(6), 0);
        assertEq(cdp.term(7), 0);
        assertEq(cdp.term(8), 0);
        assertEq(cdp.term(9), 0);
        assertEq(cdp.term(10), 0);
        bool tempBool = p1.callUpdateTerm(cdp,6,1 days);
        assertTrue(!tempBool);
        for(uint8 i = 6 ; i <= 10; i++) {
            admin.callUpdateTerm(cdp,i,2 days);
            assertEq(cdp.term(i), 2 * 86400);
        }
        for(i = 0 ; i <= 5; i++) {
            tempBool = admin.callUpdateTerm(cdp,i,2 days);
            assertTrue(!tempBool);
        }
    }

    function testChangeState() public {
        setup();
        assertTrue(cdp.enable(0));
        assertTrue(cdp.enable(1));
        assertTrue(cdp.enable(2));
        assertTrue(cdp.enable(3));
        assertTrue(cdp.enable(4));
        assertTrue(cdp.enable(5));
        assertTrue(!cdp.enable(6));
        assertTrue(!cdp.enable(7));
        assertTrue(!cdp.enable(8));
        assertTrue(!cdp.enable(9));
        assertTrue(!cdp.enable(10));
        bool tempBool = p1.callChangeState(cdp,6,true);
        assertTrue(!tempBool);
        for(uint8 i = 6 ; i <= 10; i++) {
            admin.callChangeState(cdp,i,true);
            assertTrue(cdp.enable(i));
        }
        for(i = 0 ; i <= 5; i++) {
            admin.callChangeState(cdp,i,false);
            assertTrue(!cdp.enable(i));
        }
    }

    function testSwitchCDPTransfer() public {
        setup();
        assertTrue(!cdp.disableCDPTransfer());
        bool tempBool = p1.callSwitchCDPTransfer(cdp,true);
        assertTrue(!tempBool);
        tempBool = admin.callSwitchCDPTransfer(cdp,true);
        assertTrue(tempBool);
        assertTrue(cdp.disableCDPTransfer());
        admin.callSwitchCDPTransfer(cdp,false);
        assertTrue(!cdp.disableCDPTransfer());
    }

    function testUpdateCreateCollateralRatio() public {
        setup();
        assertEq(cdp.createCollateralRatio(), 2 * RAY);
        assertEq(cdp.createRatioTolerance(), RAY / 20);
        bool tempBool = p1.callUpdateCreateCollateralRatio(cdp, 3 * RAY, RAY * 7 / 100);
        assertTrue(!tempBool);
        tempBool = admin.callUpdateCreateCollateralRatio(cdp, 3 * RAY, RAY * 7 / 100);
        assertTrue(tempBool);
        assertEq(cdp.createCollateralRatio(), 3 * RAY);
        assertEq(cdp.createRatioTolerance(), RAY * 7 / 100);
        tempBool = admin.callUpdateCreateCollateralRatio(cdp, 3 * RAY, RAY * 11 / 100);
        assertTrue(!tempBool);
        assertEq(cdp.liquidationRatio(), RAY * 3 / 2);
        tempBool = admin.callUpdateCreateCollateralRatio(cdp, RAY * 155 / 100, RAY / 20);
        assertTrue(tempBool);
        tempBool = admin.callUpdateCreateCollateralRatio(cdp, RAY * 154 / 100, RAY / 20);
        assertTrue(!tempBool);
    }

    function testUpdateLiquidationRatio() public {
        setup();
        assertEq(cdp.liquidationRatio(), RAY * 3 / 2);
        bool tempBool = p1.callUpdateLiquidationRatio(cdp, RAY * 2);
        assertTrue(!tempBool);
        tempBool = admin.callUpdateLiquidationRatio(cdp, RAY * 2);
        assertTrue(tempBool);
        assertEq(cdp.liquidationRatio(), RAY * 2);
        tempBool = admin.callUpdateLiquidationRatio(cdp, RAY * 19 / 20);
        assertTrue(!tempBool);
    }

    function testUpdateLiquidationPenalty() public {
        setup();
        assertEq(cdp.liquidationPenalty1(), RAY * 113 / 100);
        assertEq(cdp.liquidationPenalty2(), RAY * 105 / 100);
        bool tempBool = p1.callUpdateLiquidationPenalty1(cdp, RAY * 12 / 10);
        assertTrue(!tempBool);
        tempBool = p1.callUpdateLiquidationPenalty2(cdp, RAY * 12 / 10);
        assertTrue(!tempBool);
        tempBool = admin.callUpdateLiquidationPenalty1(cdp, RAY * 12 / 10);
        assertTrue(tempBool);
        tempBool = admin.callUpdateLiquidationPenalty2(cdp, RAY * 12 / 10);
        assertTrue(tempBool);
        assertEq(cdp.liquidationPenalty1(), RAY * 12 / 10);
        assertEq(cdp.liquidationPenalty2(), RAY * 12 / 10);
        tempBool = admin.callUpdateLiquidationPenalty1(cdp, RAY * 19 / 20);
        assertTrue(!tempBool);
        tempBool = admin.callUpdateLiquidationPenalty2(cdp, RAY * 19 / 20);
        assertTrue(!tempBool);
    }

    function testUpdateDebtCeiling() public {
        setup();
        assertEq(cdp.debtCeiling(), 100000000000);
        bool tempBool = p1.callUpdateDebtCeiling(cdp, 200000000000);
        assertTrue(!tempBool);
        tempBool = admin.callUpdateDebtCeiling(cdp, 200000000000);
        assertTrue(tempBool);
        assertEq(cdp.debtCeiling(), 200000000000);
    }

    function testSetLiquidator() public {
        setup();
        assertEq(cdp.liquidator(), liquidator);
        bool tempBool = p1.callSetLiquidator(cdp, p2);
        assertTrue(!tempBool);
        tempBool = admin.callSetLiquidator(cdp, p2);
        assertTrue(tempBool);
        assertEq(cdp.liquidator(), p2);
    }

    function testSetOracle() public {
        setup();
        assertEq(uint(cdp.ASSET_COLLATERAL()),uint(ASSET_BTC));
        assertEq(cdp.priceOracle(),oracle);
        TimefliesOracle oracle3 = new TimefliesOracle("BTCOracle",paiDAO,RAY,ASSET_BTC);
        bool tempBool = p1.callSetOracle(cdp,oracle3);
        assertTrue(!tempBool);
        tempBool = admin.callSetOracle(cdp,oracle3);
        assertTrue(tempBool);
        assertEq(cdp.priceOracle(),oracle3);
    }

    function testSetSetting() public {
        setup();
        assertEq(cdp.setting(), setting);
        Setting setting2 = new Setting(paiDAO);
        admin.callUpdateRatioLimit(setting2, ASSET_BTC, RAY * 3);
        admin.callUpdateLendingRate(setting2, RAY * 102 / 1000);

        bool tempBool = p1.callSetSetting(cdp, setting2);
        assertTrue(!tempBool);
        tempBool = admin.callSetSetting(cdp, setting2);
        assertTrue(tempBool);
        assertEq(cdp.setting(), setting2);
        assertEq(cdp.annualizedInterestRate(),RAY / 10);
        assertEq(cdp.secondInterestRate(),1000000003022265980097387650);
    }

    function testSetFinance() public {
        setup();
        assertEq(cdp.finance(), finance);
        bool tempBool = p1.callSetFinance(cdp, p2);
        assertTrue(!tempBool);
        tempBool = admin.callSetFinance(cdp, p2);
        assertTrue(tempBool);
        assertEq(cdp.finance(), p2);
    }
}

contract FunctionTest1 is TestBase {
    function testTransferCDP() public {
        setup();
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        uint idx = 1;
        (,address owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//0

        p1.callTransferCDPOwnership(cdp,idx,p2,0);
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//1

        p2.callTransferCDPOwnership(cdp,idx,p1,200000000);
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//2
        bool tempBool = p1.callBuyCDP(cdp,idx,200000000,ASSET_PAI);
        assertTrue(tempBool);//3
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//4
        assertEq(flow.balance(p2,ASSET_PAI),200000000);//5
        assertEq(flow.balance(p1,ASSET_PAI),800000000);//6
    }

    function testTransferCDPFail() public {
        setup();
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        uint idx = 1;
        (,address owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//0

        admin.callGlobalShutDown(setting);
        bool tempBool = p1.callTransferCDPOwnership(cdp,idx,p2,0);
        assertTrue(!tempBool);//1
        admin.callGlobalReopen(setting);
        tempBool = p1.callTransferCDPOwnership(cdp,idx,p2,0);
        assertTrue(tempBool);//2
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//3
        tempBool = p2.callTransferCDPOwnership(cdp,idx,p1,0);
        assertTrue(tempBool);//5
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//6

        admin.callSwitchCDPTransfer(cdp,true);
        tempBool = p1.callTransferCDPOwnership(cdp,idx,p2,0);
        assertTrue(!tempBool);//7
        admin.callSwitchCDPTransfer(cdp,false);
        tempBool = p1.callTransferCDPOwnership(cdp,idx,p2,0);
        assertTrue(tempBool);//8
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//9

        tempBool = p1.callTransferCDPOwnership(cdp,idx,p2,0);
        assertTrue(!tempBool);//10
        tempBool = p2.callTransferCDPOwnership(cdp,idx,p1,0);
        assertTrue(tempBool);//11
        tempBool = p1.callTransferCDPOwnership(cdp,idx + 1,p2,0);
        assertTrue(!tempBool);//12
        tempBool = p1.callTransferCDPOwnership(cdp,idx,p1,0);
        assertTrue(!tempBool);//13
    }

    function testBuyCDPFail() public {
        setup();
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        uint idx = 1;
        (,address owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//0
        admin.callAddMember(paiDAO,admin,"Minter@STCoin");
        admin.callMint(paiIssuer,100000000,p2);

        
        p1.callTransferCDPOwnership(cdp,idx,p2,1000000);
        admin.callGlobalShutDown(setting);
        bool tempBool = p2.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(!tempBool);//1
        admin.callGlobalReopen(setting);
        tempBool = p2.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(tempBool);//2
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//3

        p2.callTransferCDPOwnership(cdp,idx,p1,1000000);
        tempBool = p1.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(tempBool);//5
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//6

        p1.callTransferCDPOwnership(cdp,idx,p2,1000000);
        admin.callSwitchCDPTransfer(cdp,true);
        tempBool = p2.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(!tempBool);//7
        admin.callSwitchCDPTransfer(cdp,false);
        tempBool = p2.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(tempBool);//8
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p2);//9

        p2.callTransferCDPOwnership(cdp,idx,p1,1000000);
        tempBool = p1.callBuyCDP(cdp,idx,1000000,ASSET_BTC);
        assertTrue(!tempBool);//10
        tempBool = p1.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(tempBool);//11
        (,owner,,,,) = cdp.CDPRecords(idx);
        assertEq(owner, p1);//12

        p1.callTransferCDPOwnership(cdp,idx,p2,1000000);
        tempBool = p2.callBuyCDP(cdp,idx,500000,ASSET_PAI);
        assertTrue(!tempBool);//13
        admin.callAddMember(paiDAO,admin,"Minter@STCoin");
        admin.callMint(paiIssuer,1000000,admin);
        assertEq(flow.balance(admin,ASSET_PAI),1000000);//15
        tempBool = admin.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(!tempBool);//16
        tempBool = p2.callBuyCDP(cdp,idx,1000000,ASSET_PAI);
        assertTrue(tempBool);//17
    }

    function testCreate() public {
        setup();
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        (uint principal, uint interest) = cdp.debtOfCDP(1);
        assertEq(principal,1000000000);
        assertEq(interest,0);
        (CDP.CDPType _type,address owner,uint collateral,uint cdpprincipal,uint accumulatedDebt, uint endTime) = cdp.CDPRecords(1);
        assertEq(uint(_type),0);
        assertEq(owner,p1);
        assertEq(collateral,2000000000);
        assertEq(cdpprincipal,1000000000);
        assertEq(accumulatedDebt,1000000000);
        assertEq(endTime,0);
        assertEq(cdp.totalCollateral(),2000000000);
        assertEq(cdp.totalPrincipal(),1000000000);
        p1.callCreateDepositBorrow(cdp,2000000000,1,4000000000,ASSET_BTC);
        (principal, interest) = cdp.debtOfCDP(2);
        assertEq(principal,2000000000);//10
        assertEq(interest,32219178); //0.196 * 30 /365 * 2000000000 = 32219178
        (_type,owner,collateral,cdpprincipal,accumulatedDebt,endTime) = cdp.CDPRecords(2);
        assertEq(uint(_type),1);
        assertEq(owner,p1);
        assertEq(collateral,4000000000);
        assertEq(cdpprincipal,2000000000);//15
        assertEq(accumulatedDebt,2000000000 + 32219178);
        assertEq(endTime, cdp.timeNow() + 30 * 86400);
        assertEq(cdp.totalCollateral(),6000000000);
        assertEq(cdp.totalPrincipal(),3000000000);
        p2.callCreateDepositBorrow(cdp,1000000000,2,2000000000,ASSET_BTC);
        (principal, interest) = cdp.debtOfCDP(3);
        assertEq(principal,1000000000);//20
        assertEq(interest,31890410); //0.194 * 60 / 365 * 1000000000 = 32219178
        (_type,owner,collateral,cdpprincipal,accumulatedDebt,endTime) = cdp.CDPRecords(3);
        assertEq(uint(_type),2);
        assertEq(owner,p2);
        assertEq(collateral,2000000000);
        assertEq(cdpprincipal,1000000000);//15
        assertEq(accumulatedDebt,1000000000 + 31890410);
        assertEq(endTime, cdp.timeNow() + 60 * 86400);
        assertEq(cdp.totalCollateral(),8000000000);
        assertEq(cdp.totalPrincipal(),4000000000);
    }

    function testCreateFail() public {
        setup();
        bool tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);
        admin.callGlobalShutDown(setting);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);

        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);

        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        assertTrue(tempBool);

        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,1950000000,ASSET_BTC);
        assertTrue(tempBool);
        tempBool = p1.callCreateDepositBorrow(cdp,1000000000,0,1949999999,ASSET_BTC);
        assertTrue(!tempBool);

        tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        tempBool = p1.callCreateDepositBorrow(cdp,499999999,0,1000000000,ASSET_BTC);
        assertTrue(!tempBool);

        tempBool = p2.callCreateDepositBorrow(cdp,1000000000,0,100000000000,ASSET_BTC);
        assertTrue(!tempBool);
    }

    function testCreateFail2() public {
        setup();
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY / 2);
        assertEq(cdp.totalPrincipal(),0);
        admin.callAddMember(paiDAO,admin,"Minter@STCoin");
        admin.callMint(paiIssuer,5000000000,admin);
        uint totalPaiSupply = paiIssuer.totalSupply();
        assertEq(totalPaiSupply,5000000000);
        bool tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        tempBool = p1.callCreateDepositBorrow(cdp,5000000000,0,10000000000,ASSET_BTC);
        assertTrue(!tempBool);
        tempBool = p1.callCreateDepositBorrow(cdp,4500000000,0,10000000000,ASSET_BTC);
        assertTrue(tempBool);
    }

    function testCreateFail3() public {
        setup();
        bool tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        admin.callChangeState(cdp,0,false);
        tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(!tempBool);
        admin.callChangeState(cdp,0,true);
        tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        admin.callTerminate(cdp);
        tempBool = p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        assertTrue(!tempBool);
    }
}

contract FunctionTest2 is TestBase {
    function testDeposit() public {
        setup();
        p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        bool tempBool = p2.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(!tempBool);
        (,,uint collateral,,,) = cdp.CDPRecords(1);
        assertEq(collateral,1000000000);
        tempBool = p1.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        (,,collateral,,,) = cdp.CDPRecords(1);
        assertEq(collateral,2000000000);
        
        admin.callGlobalShutDown(setting);
        tempBool = p1.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(tempBool);

        tempBool = p1.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(tempBool);
        admin.callTerminate(cdp);
        tempBool = p1.callDeposit(cdp,1,1000000000,ASSET_BTC);
        assertTrue(!tempBool);

    }

    function testRepay() public {
        setup();
        p1.callCreateDepositBorrow(cdp,500000000,0,1000000000,ASSET_BTC);
        bool tempBool = p2.callRepay(cdp,1,100000000,ASSET_PAI);
        assertTrue(!tempBool);
        (,,,uint principal,,) = cdp.CDPRecords(1);
        assertEq(principal,500000000);
        tempBool = p1.callRepay(cdp,1,100000000,ASSET_PAI);
        assertTrue(tempBool);
        (,,,principal,,) = cdp.CDPRecords(1);
        assertEq(principal,400000000);

        admin.callGlobalShutDown(setting);
        tempBool = p1.callRepay(cdp,1,10000000,ASSET_PAI);
        assertTrue(!tempBool);
        admin.callGlobalReopen(setting);
        tempBool = p1.callRepay(cdp,1,10000000,ASSET_PAI);
        assertTrue(tempBool);

        tempBool = p1.callRepay(cdp,1,10000000,ASSET_PAI);
        assertTrue(tempBool);
        admin.callTerminate(cdp);
        tempBool = p1.callRepay(cdp,1,10000000,ASSET_PAI);
        assertTrue(!tempBool);
    }

    function testRepayCalculation() public {
        setup();
        admin.callUpdateLendingRate(setting, RAY * 202 / 1000);
        cdp.updateBaseInterestRate();
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        admin.callAddMember(paiDAO,admin,"Minter@STCoin");
        admin.callMint(paiIssuer,5000000000,p1);
        cdp.fly(1000000);
        (uint principal, uint interest) = cdp.debtOfCDP(1);
        assertEq(principal,1000000000);
        assertEq(interest,5798123);//1.000000005781378656804591713**1000000*1000000000 - 1000000000 = 5798123
        p1.callRepay(cdp,1,5000000,ASSET_PAI);
        (principal, interest) = cdp.debtOfCDP(1);
        assertEq(principal,1000000000);
        assertEq(interest,798123);
        cdp.fly(1000000);
        assertEq(flow.balance(finance,ASSET_PAI),5000000);
        (principal, interest) = cdp.debtOfCDP(1);
        assertEq(principal,1000000000);
        assertEq(interest,6600873);//1.000000005781378656804591713**1000000*1000798123 - 1000000000 = 6600873
        
        //test overpayed
        p1.callRepay(cdp,1,1500000000,ASSET_PAI);
        (principal, interest) = cdp.debtOfCDP(1);
        assertEq(principal,0);
        assertEq(interest,0);
        assertEq(flow.balance(finance,ASSET_PAI),5000000 + 6600873);

        //test tolorance
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        p1.callCreateDepositBorrow(cdp,1000000000,0,2000000000,ASSET_BTC);
        cdp.fly(1000000);
        (principal, interest) = cdp.debtOfCDP(2);
        assertEq(principal,1000000000);
        assertEq(interest,5798123);
        (principal, interest) = cdp.debtOfCDP(3);
        assertEq(principal,1000000000);
        assertEq(interest,5798123);
        p1.callRepay(cdp,2,1005777190,ASSET_PAI);//1005798123/(1.000000005781378656804591713**3600) = 1005777189
        p1.callRepay(cdp,3,1005777189,ASSET_PAI);
        (principal, interest) = cdp.debtOfCDP(2);
        assertEq(principal,0);
        assertEq(interest,0);
        (principal, interest) = cdp.debtOfCDP(3);
        assertEq(principal,20934);
        assertEq(interest,0);
        assertEq(flow.balance(finance,ASSET_PAI),5000000 + 6600873 + 5777190 + 5798123);

        //test tolorance won't work
        admin.callUpdateLendingRate(setting, RAY * 2 / 10);
        cdp.updateBaseInterestRate();
        p1.callCreateDepositBorrow(cdp,1000000000,1,2000000000,ASSET_BTC);
        (principal, interest) = cdp.debtOfCDP(4);
        assertEq(principal,1000000000);
        assertEq(interest,16109589);
        p1.callRepay(cdp,4,1016109588,ASSET_PAI);//16109589+1000000000 = 1016109588 + 1
        (principal, interest) = cdp.debtOfCDP(4);
        assertEq(principal,1);
        assertEq(interest,0);
        assertEq(flow.balance(finance,ASSET_PAI), 5000000 + 6600873 + 5777190 + 5798123 + 16109589);
    }

    function testUnsafe() public {
        setup();
        
        uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._30DAYS);
        assertTrue(cdp.safe(idx));
        cdp.fly(30 days);
        assertTrue(cdp.safe(idx));
        cdp.fly(3 days);
        assertTrue(cdp.safe(idx));
        cdp.fly(1);
        assertTrue(!cdp.safe(idx));

        idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);
        assertTrue(cdp.safe(idx));
        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY / 2);
        p1.callUpdatePrice(oracle, RAY / 2);
        p2.callUpdatePrice(oracle, RAY / 2);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY / 2);
        assertEq(oracle.getPrice(), RAY / 2);
        assertTrue(!cdp.safe(idx));

        idx = cdp.createDepositBorrow.value(4000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);
        assertTrue(cdp.safe(idx));
        cdp.fly(1 years);
        assertTrue(cdp.safe(idx));
        cdp.fly(1 years);
        assertTrue(!cdp.safe(idx));
    }

    function testLiquidationCase1() public {
        setup();
        admin.callUpdateLiquidationRatio(cdp, RAY);
        uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);
        
        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY / 4);
        p1.callUpdatePrice(oracle, RAY / 4);
        p2.callUpdatePrice(oracle, RAY / 4);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY / 4);
        assertEq(oracle.getPrice(), RAY / 4);
        assertEq(liquidator.totalCollateral(), 0);
        cdp.liquidate(idx);
        assertEq(liquidator.totalCollateral(), 1000000000);
    }

    function testLiquidationCase2() public {
        setup();
        uint idx = cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        admin.callUpdateLiquidationRatio(cdp, RAY * 2);
        admin.callUpdateLiquidationPenalty1(cdp, RAY);

        assertTrue(cdp.safe(idx));
        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY / 2);
        p1.callUpdatePrice(oracle, RAY / 2);
        p2.callUpdatePrice(oracle, RAY / 2);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY / 2);
        assertEq(oracle.getPrice(), RAY / 2);
        assertTrue(!cdp.safe(idx));

        assertEq(cdp.totalPrincipal(), 4000000000);
        (uint principal,uint interest) = cdp.debtOfCDP(idx);
        assertEq(add(principal,interest), 4000000000);
        assertEq(liquidator.totalCollateral(), 0);
        assertEq(liquidator.totalDebt(), 0);

        uint emm = flow.balance(this, ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(cdp.totalPrincipal(), 0);
        (principal, interest) = cdp.debtOfCDP(idx);
        assertEq(add(principal,interest), 0);
        assertEq(liquidator.totalCollateral(), 8000000000);
        assertEq(liquidator.totalDebt(), 4000000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm, 2000000000);//10000000000 - 8000000000 = 2000000000
    }

    function testLiqudateFail() public {
        setup();
        cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(4000000000,CDP.CDPType.CURRENT);
        admin.callUpdateLiquidationRatio(cdp, RAY * 2);
        admin.callUpdateLiquidationPenalty1(cdp, RAY);

        assertTrue(cdp.safe(1));
        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY / 2);
        p1.callUpdatePrice(oracle, RAY / 2);
        p2.callUpdatePrice(oracle, RAY / 2);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY / 2);
        assertEq(oracle.getPrice(), RAY / 2);
        assertTrue(!cdp.safe(1));

        assertEq(cdp.totalPrincipal(), 20000000000);
        bool tempBool = p1.callLiquidate(cdp,1);
        assertTrue(tempBool);
        assertEq(cdp.totalPrincipal(), 16000000000);

        tempBool = p1.callLiquidate(cdp,2);
        assertTrue(tempBool);
        assertEq(cdp.totalPrincipal(), 12000000000);

        tempBool = p1.callLiquidate(cdp,3);
        assertTrue(tempBool);
        assertEq(cdp.totalPrincipal(), 8000000000);

        admin.callRemoveMember(paiDAO,cdp,"BTCCDP");
        tempBool = p1.callLiquidate(cdp,4);
        assertTrue(!tempBool);
        admin.callAddMember(paiDAO,cdp,"BTCCDP");
        tempBool = p1.callLiquidate(cdp,4);
        assertTrue(tempBool);
        assertEq(cdp.totalPrincipal(), 4000000000);
    }
}


contract LiquidationPenaltyTest is TestBase {
    function penaltySetup() public returns (uint) {
        setup();
        admin.callUpdateLiquidationRatio(cdp, RAY * 2);

        uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);

        return idx;
    }

    function testPenaltyCase1() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationRatio(cdp, RAY * 21 / 10);
        admin.callUpdateLiquidationPenalty1(cdp, RAY * 15 / 10);

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC) - emm, 500000000);
    }

    function testPenaltyCase2() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationPenalty1(cdp, RAY * 15 / 10);

        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY * 8 / 10);
        p1.callUpdatePrice(oracle, RAY * 8 / 10);
        p2.callUpdatePrice(oracle, RAY * 8 / 10);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 8 / 10);
        assertEq(oracle.getPrice(), RAY * 8 / 10);
        assertTrue(!cdp.safe(idx));

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC) - emm, 125000000);
    }

    function testPenaltyParity() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationPenalty1(cdp, RAY * 15 / 10);

        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY * 5 / 10);
        p1.callUpdatePrice(oracle, RAY * 5 / 10);
        p2.callUpdatePrice(oracle, RAY * 5 / 10);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 5 / 10);
        assertEq(oracle.getPrice(), RAY * 5 / 10);
        assertTrue(!cdp.safe(idx));

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC), emm);
    }

    function testPenaltyUnder() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationPenalty1(cdp, RAY * 15 / 10);

        admin.callModifySensitivityRate(oracle, RAY);
        admin.callUpdatePrice(oracle, RAY * 4 / 10);
        p1.callUpdatePrice(oracle, RAY * 4 / 10);
        p2.callUpdatePrice(oracle, RAY * 4 / 10);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 4 / 10);
        assertEq(oracle.getPrice(), RAY * 4 / 10);
        assertTrue(!cdp.safe(idx));

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC), emm);
    }

    function testSettlementWithPenalty() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationPenalty1(cdp, RAY * 15 / 10);

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        admin.callTerminate(cdp);

        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC) - emm, 1000000000);
    }

    function testSettlementWithoutPenalty() public {
        uint idx = penaltySetup();

        admin.callUpdateLiquidationPenalty1(cdp, RAY);

        (,,uint collateral,,,) = cdp.CDPRecords(idx);
        assertEq(collateral, 2000000000);
        admin.callTerminate(cdp);

        uint emm = flow.balance(this,ASSET_BTC);
        cdp.liquidate(idx);
        assertEq(flow.balance(this,ASSET_BTC) - emm, 1000000000);
    }
}

contract MultipleInterestTest is TestBase {

    function testParam() public {
        setup();
        assertEq(cdp.getInterestRate(CDP.CDPType._30DAYS), RAY * 196 / 1000);
        assertEq(cdp.getInterestRate(CDP.CDPType._60DAYS), RAY * 194 / 1000);
        assertEq(cdp.getInterestRate(CDP.CDPType._90DAYS), RAY * 192 / 1000);
        assertEq(cdp.getInterestRate(CDP.CDPType._180DAYS), RAY * 190 / 1000);
        assertEq(cdp.getInterestRate(CDP.CDPType._360DAYS), RAY * 188 / 1000);
        assertEq(cdp.getInterestRate(CDP.CDPType.FLEXIABLE1), RAY / 5);
        assertEq(cdp.getInterestRate(CDP.CDPType.FLEXIABLE2), RAY / 5);
        assertEq(cdp.getInterestRate(CDP.CDPType.FLEXIABLE3), RAY / 5);
        assertEq(cdp.getInterestRate(CDP.CDPType.FLEXIABLE4), RAY / 5);
        assertEq(cdp.getInterestRate(CDP.CDPType.FLEXIABLE5), RAY / 5);
        assertEq(cdp.term(1), 30 * 86400);
        assertEq(cdp.term(2), 60 * 86400);
        assertEq(cdp.term(3), 90 * 86400);
        assertEq(cdp.term(4), 180 * 86400);
        assertEq(cdp.term(5), 360 * 86400);
        assertEq(cdp.term(6), 0);
        assertEq(cdp.term(7), 0);
        assertEq(cdp.term(8), 0);
        assertEq(cdp.term(9), 0);
        assertEq(cdp.term(10), 0);
    }

    function testCalculation() public {
        setup();
        uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._30DAYS);
        (uint principal, uint interest) = cdp.debtOfCDP(idx);
        assertEq(principal,1000000000);
        assertEq(interest,16109589);//0.196 * 30 * 1000000000 / 365 = 16109589

        idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._60DAYS);
        (principal, interest) = cdp.debtOfCDP(idx);
        assertEq(principal,1000000000);
        assertEq(interest,31890410);//0.194 * 60 * 1000000000 / 365 = 31890410

        idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._90DAYS);
        (principal, interest) = cdp.debtOfCDP(idx);
        assertEq(principal,1000000000);
        assertEq(interest,47342465);//0.192 * 90 * 1000000000 / 365 = 47342465

        idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._180DAYS);
        (principal, interest) = cdp.debtOfCDP(idx);
        assertEq(principal,1000000000);
        assertEq(interest,93698630);//0.190 * 180 * 1000000000 / 365 = 93698630

        idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType._360DAYS);
        (principal, interest) = cdp.debtOfCDP(idx);
        assertEq(principal,1000000000);
        assertEq(interest,185424657);//0.188 * 360 * 1000000000 / 365 = 185424657
    }
}