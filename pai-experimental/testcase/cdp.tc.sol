pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/settlement.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";

contract TestBase is Template, DSTest, DSMath {
    TimefliesCDP internal cdp;
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
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

    function() public payable {

    }

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();

        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",3);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"SettlementContract","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"BTCOracle");
        admin.callAddMember(paiDAO,p1,"BTCOracle");
        admin.callAddMember(paiDAO,p2,"BTCOracle");
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callAddMember(paiDAO,admin,"SettlementContract");

        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();

        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());

        liquidator = new Liquidator(oracle, paiIssuer);//todo
        liquidator.setAssetBTC(ASSET_BTC);//todo
        setting = new Setting(paiDAO);
        finance = new Finance(paiIssuer); // todo
        admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

        cdp = new TimefliesCDP(paiDAO,paiIssuer, oracle, liquidator,setting,finance,ASSET_BTC,1000000000000);
        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,cdp,"PAIMINTER");

        btcIssuer.mint(1000000000000, this);
    }

    function setupTest() public {
        setup();
        admin.callUpdatePrice(oracle, RAY * 99/100);
        p1.callUpdatePrice(oracle, RAY * 99/100);
        p2.callUpdatePrice(oracle, RAY * 99/100);
        oracle.fly(50);
        admin.callUpdatePrice(oracle, RAY * 99/100);
        assertEq(oracle.getPrice(), RAY * 99/100);

    }
}

contract SettingTest is TestBase {
    function testSetAssetCollateral() public {
        setup();
        // assertEq(uint(cdp.ASSET_COLLATERAL()),uint(ASSET_BTC));
        // assertEq(cdp.priceOracle(),oracle);
        //tempBool = p1.callSetAssetCollateral(cdp,uint96(123),address(0x456));
        // assertTrue(!tempBool);
        bool tempBool = admin.callSetAssetCollateral(cdp,uint96(123),address(p2));
        assertTrue(tempBool);
        // assertEq(uint(cdp.ASSET_COLLATERAL()),123);
        // assertEq(cdp.priceOracle(),address(0x456));
    }
}

contract FunctionTest is TestBase {

}

// contract CDPTest is TestBase {

//     function testBasic() public  {
//         setup();
//         uint emm = 1000000000000;

//         assertEq(cdp.totalCollateral(), 0);
//         assertEq(cdp.totalPrincipal(), 0);

//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         assertEq(idx,1);
//         assertEq(cdp.totalCollateral(), 200000000);
//         assertEq(cdp.totalPrincipal(), 100000000);
//         assertEq(flow.balance(this, ASSET_PAI),emm + 100000000);
//         assertEq(flow.balance(this, ASSET_BTC),emm - 200000000);
//         (uint principal,uint interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 100000000);
//         assertEq(interest, 0);

//         cdp.repay.value(50000000, ASSET_PAI)(idx);
//         assertEq(cdp.totalCollateral(), 200000000);
//         assertEq(cdp.totalPrincipal(), 50000000);
//         assertEq(flow.balance(this, ASSET_PAI),emm + 50000000);
//         assertEq(flow.balance(this, ASSET_BTC),emm - 200000000);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 50000000);
//         assertEq(interest, 0);

//         cdp.repay.value(50000000, ASSET_PAI)(idx);
//         assertEq(cdp.totalCollateral(), 0);
//         assertEq(cdp.totalPrincipal(), 0);
//         assertEq(flow.balance(this, ASSET_PAI),emm);
//         assertEq(flow.balance(this, ASSET_BTC),emm);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 0);
//         assertEq(interest, 0);

//         //test borrow limit
//         bool tempBool;
//         tempBool = cdp.call.value(20000000, ASSET_BTC)(abi.encodeWithSelector(cdp.createDepositBorrow.selector,9000000,CDP.CDPType._30DAYS));
//         assertTrue(!tempBool);
//     }

//     function testTransferCDP() public {
//         setup();
//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         (,address owner,,,,) = cdp.CDPRecords(idx);
//         assertEq(owner, this);

//         cdp.transferCDPOwnership(idx, 0x123,0);
//         (,owner,,,,) = cdp.CDPRecords(idx);
//         assertEq(owner, 0x123);
//         bool tempBool;
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.transferCDPOwnership.selector,idx, 0x456));
//         assertTrue(!tempBool);

//         FakePerson p1 = new FakePerson();
//         paiIssuer.mint(1000000000000, p1);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         (,owner,,,,) = cdp.CDPRecords(idx);
//         assertEq(owner, this);
//         cdp.transferCDPOwnership(idx, p1,100000000);
//         (,owner,,,,) = cdp.CDPRecords(idx);
//         assertEq(owner, this);
//         tempBool = p1.callBuyCDP(cdp,idx,50000000,uint96(ASSET_PAI));
//         assertTrue(!tempBool);
//         tempBool = p1.callBuyCDP(cdp,idx,110000000,uint96(ASSET_PAI));
//         assertTrue(!tempBool);
//         uint emm = flow.balance(this,ASSET_PAI);
//         tempBool = p1.callBuyCDP(cdp,idx,100000000,uint96(ASSET_PAI));
//         assertTrue(tempBool);
//         (,owner,,,,) = cdp.CDPRecords(idx);
//         assertEq(owner, p1);
//         assertEq(flow.balance(this,ASSET_PAI),emm + 100000000);
//     }
    
//     function testSetLiquidationRatio() public {
//         setup();
//         bool tempBool;
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateLiquidationRatio.selector,1130000000000000000000000000));
//         assertTrue(tempBool);
//         assertEq(cdp.liquidationRatio(), 1130000000000000000000000000);
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateLiquidationRatio.selector,990000000000000000000000000));
//         assertTrue(!tempBool);
//     }

//     function testSetLiquidationPenalty() public {
//         setup();
//         bool tempBool;
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateLiquidationPenalty.selector,1500000000000000000000000000));
//         assertTrue(tempBool);
//         assertEq(cdp.liquidationPenalty(), 1500000000000000000000000000);
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateLiquidationPenalty.selector,990000000000000000000000000));
//         assertTrue(!tempBool);
//     }

//     function testSetDebtCeiling() public {
//         setup();
//         cdp.updateDebtCeiling(1000000000000);
//         assertEq(cdp.debtCeiling(), 1000000000000);
//     }

//     function testSetPriceOracle() public {
//         setup();
//         cdp.setPriceOracle(PriceOracle(0x123));
//         assertEq(cdp.priceOracle(), 0x123);
//     }

//     function testRepay() public {
//         setup();
//         uint emm = 1000000000000;
//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.repay.value(50000000, ASSET_PAI)(idx);

//         assertEq(cdp.totalCollateral(), 200000000);
//         assertEq(cdp.totalPrincipal(), 50000000);
//         assertEq(flow.balance(this, ASSET_PAI),emm + 50000000);
//         assertEq(flow.balance(this, ASSET_BTC),emm - 200000000);
//         (uint principal,uint interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 50000000);
//         assertEq(interest, 0);

//         cdp.repay.value(50000000, ASSET_PAI)(idx);
//         assertEq(cdp.totalCollateral(), 0);
//         assertEq(cdp.totalPrincipal(), 0);
//         assertEq(flow.balance(this, ASSET_PAI),emm);
//         assertEq(flow.balance(this, ASSET_BTC),emm);
//         (principal,interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 0);
//         assertEq(interest, 0);

//         //overpayed
//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.repay.value(200000000, ASSET_PAI)(idx);
//         assertEq(flow.balance(this, ASSET_PAI),emm);
//         assertEq(flow.balance(this, ASSET_BTC),emm);
//         (principal,interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 0);
//         assertEq(interest, 0);
//     }

//     function testUnsafe() public {
//         setup();
//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         assertTrue(cdp.safe(idx));
//         oracle.updatePrice(ASSET_BTC, RAY / 2);
//         assertTrue(!cdp.safe(idx));

//         oracle.updatePrice(ASSET_BTC, RAY);
//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._30DAYS);
//         assertTrue(cdp.safe(idx));
//         cdp.fly(30 days);
//         assertTrue(cdp.safe(idx));
//         cdp.fly(3 days);
//         assertTrue(cdp.safe(idx));
//         cdp.fly(1);
//         assertTrue(!cdp.safe(idx));
//     }

//     function testLiquidationCase1() public {
//         setup();
//         cdp.updateLiquidationRatio(1000000000000000000000000000);
//         uint idx = cdp.createDepositBorrow.value(100000000, ASSET_BTC)(50000000,CDP.CDPType.CURRENT);
//         oracle.updatePrice(ASSET_BTC, RAY / 4);

//         assertEq(liquidator.totalCollateralBTC(), 0);
//         cdp.liquidate(idx);
//         assertEq(liquidator.totalCollateralBTC(), 100000000);
//     }

//     function testLiquidationCase2() public {
//         setup();
//         uint idx = cdp.createDepositBorrow.value(100000000, ASSET_BTC)(40000000,CDP.CDPType.CURRENT);
//         cdp.updateLiquidationRatio(2000000000000000000000000000);
//         cdp.updateLiquidationPenalty(1000000000000000000000000000);

//         assertTrue(cdp.safe(idx));
//         oracle.updatePrice(ASSET_BTC, RAY / 2);
//         assertTrue(!cdp.safe(idx));

//         assertEq(cdp.totalPrincipal(), 40000000);
//         (uint principal,uint interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 40000000);
//         assertEq(liquidator.totalCollateralBTC(), 0);
//         assertEq(liquidator.totalDebtPAI(), 0);

//         uint emm = flow.balance(this, ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(cdp.totalPrincipal(), 0);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 0);
//         assertEq(liquidator.totalCollateralBTC(), 80000000);
//         assertEq(liquidator.totalDebtPAI(), 40000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm, 20000000);//100000000 - 80000000 = 20000000
//     }

//     function testDeposit() public {
//         setup();
//         uint idx = cdp.createDepositBorrow.value(100000000, ASSET_BTC)(50000000,CDP.CDPType.CURRENT);
//         cdp.deposit.value(100000000, ASSET_BTC)(idx);
//         assertEq(cdp.totalCollateral(), 200000000);
//     }

//     /// TODO implement debt ceiling in cdp.sol
//     function testBorrowFailOverDebtCeiling() public {

//     }

//     /// TODO implement debt ceiling in cdp.sol
//     function testDebtCeiling() public {

//     }
// }
 
// contract baseInterestRateTest is TestBase {
//     function testEraInit() public {
//         setup();
//         assertEq(uint(cdp.era()), now);
//     }

//     function testEraFlies() public {
//         setup();
//         cdp.fly(20);
//         assertEq(uint(cdp.era()), now + 20);
//     }

//     function feeSetup() public returns (uint) {
//         setup();
//         oracle.updatePrice(ASSET_BTC, RAY * 10);
//         cdp.updateBaseInterestRate(1050000000000000000000000000);
//         cdp.updateLiquidationRatio(RAY);
//         uint idx = cdp.createDepositBorrow.value(10000000000, ASSET_BTC)(10000000000,CDP.CDPType.CURRENT);

//         return idx;
//     }

//     function testFeeFlies() public {
//         uint idx = feeSetup();
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 10000000000);
//         cdp.fly(1 years);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 10500000000);
//         cdp.fly(1 years);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 11025000000);
//     }

//     function testFeeRepay() public {
//         uint idx = feeSetup();
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(cdp.totalPrincipal(), 10000000000);
//         assertEq(add(principal,interest), 10000000000);

//         cdp.fly(1 years);
//         cdp.updateRates();

//         assertEq(cdp.totalPrincipal(), 10000000000);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 10000000000);
//         assertEq(interest,500000000);

//         //pay for interest first
//         cdp.repay.value(5000000000, ASSET_PAI)(idx);
//         assertEq(cdp.totalPrincipal(), 5500000000);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 5500000000);
//         assertEq(interest, 0);

//         cdp.fly(1 years);
//         cdp.updateRates();

//         assertEq(cdp.totalPrincipal(), 5500000000);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 5500000000);
//         assertEq(interest, 275000000);//(5500000000+275000000)=5500000000*1.05

//         //pay for interest first
//         cdp.repay.value(5000000, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal, 5500000000);
//         assertEq(interest, 270000000);
//     }

//     function testFeeSafe() public {
//         uint idx = feeSetup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         assertTrue(cdp.safe(idx));
//         cdp.fly(1 years);
//         assertTrue(!cdp.safe(idx));
//     }

//     function testFeeLiquidate() public {
//         uint idx = feeSetup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         cdp.fly(1 years);
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 10500000000);
//         cdp.liquidate(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 0);
//         assertEq(liquidator.totalDebtPAI(), 10000000000);
//     }

//     function testFeeLiquidateRounding() {
//         uint idx = feeSetup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         cdp.updateLiquidationRatio(1500000000000000000000000000);
//         cdp.updateLiquidationPenalty(1400000000000000000000000000);
//         cdp.updateBaseInterestRate(1100000000000000000000000000);
//         for (uint i = 0; i <= 50; i ++) {
//             cdp.fly(10);
//         }
//         uint256 debtAfterFly = rmul(10000000000, rpow(cdp.baseInterestRate(), 510));
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), debtAfterFly);
//         cdp.liquidate(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(add(principal,interest), 0);
//         assertEq(liquidator.totalDebtPAI(), 10000000000);
//     }
// }

// contract LiquidationPenaltyTest is TestBase {
//     function penaltySetup() public returns (uint) {
//         setup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         cdp.updateLiquidationRatio(RAY * 2);

//         uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);

//         return idx;
//     }

//     function testPenaltyCase1() public {
//         uint idx = penaltySetup();
    
//         cdp.updateLiquidationRatio(RAY * 21 / 10);
//         cdp.updateLiquidationPenalty(RAY * 15 / 10);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC) - emm, 500000000);
//     }

//     function testPenaltyCase2() public {
//         uint idx = penaltySetup();

//         cdp.updateLiquidationPenalty(RAY * 15 / 10);
//         oracle.updatePrice(ASSET_BTC, RAY * 8 / 10);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC) - emm, 125000000);
//     }

//     function testPenaltyParity() public {
//         uint idx = penaltySetup();

//         cdp.updateLiquidationPenalty(RAY * 15 / 10);
//         oracle.updatePrice(ASSET_BTC, RAY * 5 / 10);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC), emm);
//     }

//     function testPenaltyUnder() public {
//         uint idx = penaltySetup();

//         cdp.updateLiquidationPenalty(RAY * 15 / 10);
//         oracle.updatePrice(ASSET_BTC, RAY * 4 / 10);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC), emm);
//     }

//     function testSettlementWithPenalty() public {
//         uint idx = penaltySetup();

//         cdp.updateLiquidationPenalty(RAY * 15 / 10);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         cdp.terminate();

//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC) - emm, 1000000000);
//     }

//     function testSettlementWithoutPenalty() public {
//         uint idx = penaltySetup();

//         cdp.updateLiquidationPenalty(RAY);

//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         assertEq(collateral, 2000000000);
//         cdp.terminate();

//         uint emm = flow.balance(this,ASSET_BTC);
//         cdp.liquidate(idx);
//         assertEq(flow.balance(this,ASSET_BTC) - emm, 1000000000);
//     }
// }

// contract LiquidationTest is TestBase {
//     function liquidationSetup() public {
//         setup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         cdp.updateLiquidationRatio(RAY);
//         cdp.updateLiquidationPenalty(RAY);
//     }

//     function liq(uint idx) internal returns (uint256) {
//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         uint debtValue = rmul(add(principal,interest), cdp.liquidationRatio());
//         return adiv(debtValue, collateral);
//     }

//     function collat(uint idx) internal returns (uint256) {
//         (,,uint collateral,,,) = cdp.CDPRecords(idx);
//         uint256 collateralValue = rmul(collateral, oracle.getPrice(ASSET_BTC));
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         uint256 debtValue = add(principal,interest);
//         return adiv(collateralValue, debtValue);
//     }

//     function testLiq() public {
//         liquidationSetup();
//         oracle.updatePrice(ASSET_BTC, RAY * 2);

//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);

//         cdp.updateLiquidationRatio(RAY);
//         assertEq(liq(idx), ASI);

//         cdp.updateLiquidationRatio(RAY * 3 / 2);
//         assertEq(liq(idx), ASI * 3 / 2);

//         oracle.updatePrice(ASSET_BTC, RAY * 6);
//         assertEq(liq(idx), ASI * 3 / 2);

//         cdp.deposit.value(1000000000, ASSET_BTC)(idx);
//         assertEq(liq(idx), ASI * 3 / 4);
//     }

//     function testCollat() public {
//         liquidationSetup();
//         oracle.updatePrice(ASSET_BTC, RAY * 2);

//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);

//         assertEq(collat(idx), ASI * 2);

//         oracle.updatePrice(ASSET_BTC, RAY * 4);
//         assertEq(collat(idx), ASI * 4);

//         cdp.repay.value(500000000, ASSET_PAI)(idx);
//         assertEq(collat(idx), ASI * 8);
//     }

//     function testLiquidationCase1() public {
//         liquidationSetup();
//         cdp.updateLiquidationRatio(RAY * 3 / 2);
//         oracle.updatePrice(ASSET_BTC, RAY * 3);
//         liquidator.setDiscount(RAY);

//         cdp.updateCreateCollateralRatio(RAY * 3 / 2, 0);
//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(1600000000,CDP.CDPType.CURRENT);
//         oracle.updatePrice(ASSET_BTC, RAY * 2);

//         assertTrue(!cdp.safe(idx));

//         cdp.liquidate(idx);

//         assertEq(liquidator.totalCollateralBTC(), 800000000);

//         uint emm1 = flow.balance(this, ASSET_PAI);
//         uint emm2 = flow.balance(this, ASSET_BTC);

//         liquidator.buyCollateral.value(400000000, ASSET_PAI)();

//         assertEq(emm1 - flow.balance(this, ASSET_PAI), 400000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm2, 200000000);

//         oracle.updatePrice(ASSET_BTC, RAY);

//         liquidator.buyCollateral.value(600000000, ASSET_PAI)();
//         assertEq(liquidator.totalCollateralBTC(), 0);
//     }

//     function testLiquidationCase2() public {
//         liquidationSetup();
//         cdp.updateLiquidationRatio(RAY * 2);
//         cdp.updateLiquidationPenalty(RAY * 3 / 2);
//         oracle.updatePrice(ASSET_BTC, RAY * 20);
//         liquidator.setDiscount(RAY);

//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(10000000000,CDP.CDPType.CURRENT);

//         oracle.updatePrice(ASSET_BTC, RAY * 15);

//         cdp.liquidate(idx);

//         assertEq(liquidator.totalDebtPAI(), 10000000000);
//         assertEq(liquidator.totalCollateralBTC(), 1000000000);

//         idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(5000000000,CDP.CDPType.CURRENT);

//         liquidator.buyCollateral.value(15000000000, ASSET_PAI)();
//         assertEq(liquidator.totalDebtPAI(), 0);
//         assertEq(liquidator.totalCollateralBTC(), 0);
//         assertEq(liquidator.totalAssetPAI(), 5000000000);
//     }
// }

// contract LiquidatorTest is TestBase {
//     function liquidatorSetup() public {
//         setup();
//         liquidator.setDiscount(RAY);
//     }

//     function testCancelDebt() public {
//         liquidatorSetup();

//         liquidator.addDebt(5000000000);
//         paiIssuer.mint(6000000000, liquidator);

//         assertEq(liquidator.totalAssetPAI(), 6000000000);
//         assertEq(liquidator.totalDebtPAI(), 5000000000);

//         liquidator.cancelDebt();
//         assertEq(liquidator.totalAssetPAI(), 1000000000);
//         assertEq(liquidator.totalDebtPAI(), 0);
//     }

//     function testBuyCollateral() public {
//         liquidatorSetup();

//         btcIssuer.mint(5000000000, liquidator);

//         uint emm1 = flow.balance(this, ASSET_PAI);
//         uint emm2 = flow.balance(this, ASSET_BTC);

//         liquidator.buyCollateral.value(3000000000, ASSET_PAI)();

//         assertEq(emm1 - flow.balance(this, ASSET_PAI), 3000000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm2, 3000000000);
//     }

//     function testBuyCollateralAll() public {
//         liquidatorSetup();

//         btcIssuer.mint(5000000000, liquidator);

//         uint emm1 = flow.balance(this, ASSET_PAI);
//         uint emm2 = flow.balance(this, ASSET_BTC);

//         liquidator.buyCollateral.value(6000000000, ASSET_PAI)();        

//         assertEq(emm1 - flow.balance(this, ASSET_PAI), 5000000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm2, 5000000000);
//     }

//     function testCancelDebtAfterBuy1() public {
//         liquidatorSetup(); 

//         liquidator.addDebt(2000000000);
//         paiIssuer.mint(1000000000, liquidator);
//         btcIssuer.mint(5000000000, liquidator);

//         liquidator.buyCollateral.value(1500000000, ASSET_PAI)();

//         assertEq(liquidator.totalAssetPAI(), 500000000);
//         assertEq(liquidator.totalDebtPAI(), 0);
//     }

//     function testCancelDebtAfterBuy2() public {
//         liquidatorSetup(); 

//         liquidator.addDebt(2000000000);
//         paiIssuer.mint(1000000000, liquidator);
//         btcIssuer.mint(5000000000, liquidator);

//         liquidator.buyCollateral.value(500000000, ASSET_PAI)();        

//         assertEq(liquidator.totalAssetPAI(), 0);
//         assertEq(liquidator.totalDebtPAI(), 500000000);
//     }
    
//     function testDiscountBuyPartial() public {
//         liquidatorSetup();

//         liquidator.setDiscount(RAY * 9 / 10);
//         oracle.updatePrice(ASSET_BTC, RAY * 2);

//         btcIssuer.mint(1000000000, liquidator);

//         uint emm1 = flow.balance(this, ASSET_PAI);
//         uint emm2 = flow.balance(this, ASSET_BTC);

//         liquidator.buyCollateral.value(900000000, ASSET_PAI)();

//         assertEq(emm1 - flow.balance(this, ASSET_PAI), 900000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm2, 500000000);

//         assertEq(liquidator.totalAssetPAI(), 900000000);
//         assertEq(liquidator.totalCollateralBTC(), 500000000);
//     }

//     function testDiscountBuyAll() public {
//         liquidatorSetup();

//         liquidator.setDiscount(RAY * 9 / 10);
//         oracle.updatePrice(ASSET_BTC, RAY * 2);

//         btcIssuer.mint(1000000000, liquidator);

//         uint emm1 = flow.balance(this, ASSET_PAI);
//         uint emm2 = flow.balance(this, ASSET_BTC);

//         liquidator.buyCollateral.value(9000000000, ASSET_PAI)();

//         assertEq(emm1 - flow.balance(this, ASSET_PAI), 1800000000);
//         assertEq(flow.balance(this, ASSET_BTC) - emm2, 1000000000);

//         assertEq(liquidator.totalAssetPAI(), 1800000000);
//         assertEq(liquidator.totalCollateralBTC(), 0);
//     }
// }

// contract SettlementTest is TestBase {
//     Settlement settlement;

//     function settlementSetup() public {
//         setup();
//         oracle.updatePrice(ASSET_BTC, RAY);
//         cdp.updateLiquidationRatio(RAY * 2);
//         cdp.updateLiquidationPenalty(RAY * 3 / 2);
//         liquidator.setDiscount(RAY);

//         settlement = new Settlement(oracle, cdp, liquidator);
//     }

//     function testSettlementNormal() public {
//         settlementSetup();

//         uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);

//         settlement.terminatePhaseOne();

//         assertTrue(!cdp.readyForPhaseTwo());
//         cdp.liquidate(idx);
//         assertEq(liquidator.totalCollateralBTC(), 500000000);
//         assertEq(liquidator.totalDebtPAI(), 500000000);
//         assertTrue(cdp.readyForPhaseTwo());
//         assertEq(cdp.totalCollateral(), 0);
//         assertEq(cdp.totalPrincipal(), 0);

//         settlement.terminatePhaseTwo();
//         liquidator.buyCollateral.value(500000000, ASSET_PAI)();
//         assertEq(liquidator.totalCollateralBTC(), 0);
//         assertEq(liquidator.totalDebtPAI(), 0);
//     }

//     function testSettlementMultipleCDPOverCollateral() public {
//         settlementSetup();

//         uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);
//         uint idx2 = cdp.createDepositBorrow.value(3000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);
//         uint idx3 = cdp.createDepositBorrow.value(5000000000, ASSET_BTC)(2000000000,CDP.CDPType.CURRENT);
//         uint emm = flow.balance(this,ASSET_BTC);

//         assertEq(cdp.totalCollateral(), 10000000000);
//         assertEq(cdp.totalPrincipal(), 3500000000);

//         oracle.updatePrice(ASSET_BTC, RAY * 2);
//         assertTrue(cdp.safe(idx));
//         assertTrue(cdp.safe(idx2));
//         assertTrue(cdp.safe(idx3));

//         settlement.terminatePhaseOne();

//         cdp.liquidate(idx2);
//         assertEq(liquidator.totalCollateralBTC(), 500000000);
//         assertEq(liquidator.totalDebtPAI(), 1000000000);

//         assertTrue(!cdp.readyForPhaseTwo());

//         cdp.quickLiquidate(2);
//         assertEq(liquidator.totalCollateralBTC(), 750000000);
//         assertEq(liquidator.totalDebtPAI(), 1500000000);

//         assertTrue(!cdp.readyForPhaseTwo());

//         cdp.quickLiquidate(3);
//         assertEq(liquidator.totalCollateralBTC(), 1750000000);
//         assertEq(liquidator.totalDebtPAI(), 3500000000);

//         assertTrue(cdp.totalPrincipal() == 0);
//         assertEq(flow.balance(this,ASSET_BTC),emm + 1750000000 + 2500000000 + 4000000000);
//         assertTrue(cdp.readyForPhaseTwo());

//         settlement.terminatePhaseTwo();

//         liquidator.buyCollateral.value(3500000000, ASSET_PAI)();
//         assertEq(liquidator.totalCollateralBTC(), 0);
//         assertEq(liquidator.totalDebtPAI(), 0);
//     }

//     function testSettlementMultipleCDPUnderCollateral() public {
//         settlementSetup();

//         uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);
//         uint idx2 = cdp.createDepositBorrow.value(3000000000, ASSET_BTC)(1000000000,CDP.CDPType.CURRENT);
//         uint idx3 = cdp.createDepositBorrow.value(5000000000, ASSET_BTC)(2000000000,CDP.CDPType.CURRENT);
//         uint emm = flow.balance(this,ASSET_BTC);

//         assertEq(cdp.totalCollateral(), 10000000000);
//         assertEq(cdp.totalPrincipal(), 3500000000);

//         oracle.updatePrice(ASSET_BTC, RAY / 10);
//         assertTrue(!cdp.safe(idx));
//         assertTrue(!cdp.safe(idx2));
//         assertTrue(!cdp.safe(idx3));

//         settlement.terminatePhaseOne();

//         cdp.liquidate(idx2);
//         assertEq(liquidator.totalCollateralBTC(), 3000000000);
//         assertEq(liquidator.totalDebtPAI(), 1000000000);

//         assertTrue(!cdp.readyForPhaseTwo());

//         cdp.quickLiquidate(2);
//         assertEq(liquidator.totalCollateralBTC(), 5000000000);
//         assertEq(liquidator.totalDebtPAI(), 1500000000);

//         assertTrue(!cdp.readyForPhaseTwo());

//         cdp.quickLiquidate(3);
//         assertEq(liquidator.totalCollateralBTC(), 10000000000);
//         assertEq(liquidator.totalDebtPAI(), 3500000000);

//         assertTrue(cdp.totalPrincipal() == 0);
//         assertEq(flow.balance(this,ASSET_BTC),emm);
//         assertTrue(cdp.readyForPhaseTwo());

//         settlement.terminatePhaseTwo();

//         liquidator.buyCollateral.value(3500000000, ASSET_PAI)();
//         assertEq(liquidator.totalCollateralBTC(), 0);
//         assertEq(liquidator.totalDebtPAI(), 0);
//     }

//     function testSettlementPhaseTwoBuyFromLiquidator() public{
//         settlementSetup();

//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);

//         assertTrue(cdp.safe(idx));
//         oracle.updatePrice(ASSET_BTC, RAY / 2);

//         assertTrue(!cdp.safe(idx));
//         cdp.liquidate(idx);

//         assertEq(liquidator.totalCollateralBTC(), 1000000000);
//         assertEq(liquidator.totalDebtPAI(), 500000000);

//         liquidator.buyCollateral.value(100000000, ASSET_PAI)();

//         assertEq(liquidator.totalCollateralBTC(), 800000000);
//         assertEq(liquidator.totalDebtPAI(), 400000000);

//         settlement.terminatePhaseOne();
//         assertTrue(!liquidator.call(abi.encodeWithSelector(liquidator.buyCollateral.selector,1000000,ASSET_PAI)));

//         settlement.terminatePhaseTwo();
//         liquidator.buyCollateral.value(100000000, ASSET_PAI)();
//         assertEq(liquidator.totalCollateralBTC(), 600000000);
//         assertEq(liquidator.totalDebtPAI(), 300000000);
//     }

//     function testSettlementFourMethods() public {
//         settlementSetup();     

//         //test whether there are grammar error!
//         uint idx = cdp.createDepositBorrow.value(1000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);
//         assertTrue(cdp.call.value(1000000000, ASSET_BTC)(abi.encodeWithSelector(cdp.deposit.selector,idx)));
//         assertTrue(cdp.call.value(1000000000, ASSET_PAI)(abi.encodeWithSelector(cdp.repay.selector,idx)));

//         assertTrue(cdp.call.value(1000000000, ASSET_BTC)(abi.encodeWithSelector(cdp.createDepositBorrow.selector,500000000,CDP.CDPType.CURRENT)));

//         //test whether terminatePhaseTwo can be called successfully!
//         assertTrue(!settlement.call(abi.encodeWithSelector(settlement.terminatePhaseTwo.selector)));
        
//         settlement.terminatePhaseOne();
//         //test whether these four method can be called successfully!
//         assertTrue(!cdp.call.value(1000000000, ASSET_BTC)(abi.encodeWithSelector(cdp.createDepositBorrow.selector,500000000,CDP.CDPType.CURRENT)));
//         assertTrue(!cdp.call.value(1000000000, ASSET_BTC)(abi.encodeWithSelector(cdp.deposit.selector,idx)));
//         assertTrue(!cdp.call.value(1000000000, ASSET_PAI)(abi.encodeWithSelector(cdp.repay.selector,idx)));
//     }

//     function testPhaseTwoReady() public {
//         settlementSetup();

//         uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);

//         settlement.terminatePhaseOne();
//         assertTrue(!settlement.call(abi.encodeWithSelector(settlement.terminatePhaseTwo.selector)));

//         cdp.liquidate(idx);

//         assertTrue(settlement.call(abi.encodeWithSelector(settlement.terminatePhaseTwo.selector)));
//     }

//     function testSettlementUpdateOracle() public {
//         settlementSetup();     

//         assertTrue(oracle.call(abi.encodeWithSelector(oracle.updatePrice.selector,ASSET_BTC, 1)));

//         settlement.terminatePhaseOne();
//         assertTrue(!oracle.call(abi.encodeWithSelector(oracle.updatePrice.selector,ASSET_BTC, 1)));
//     }

// }

// contract MultipleInterestTest is TestBase {

//     function testCalculate() public {
//         setup();
//         uint rate = cdp.baseInterestRate();
//         assertEq(rpow(rate,1 years),RAY * 12 / 10);
//         cdp.updateBaseInterestRate(RAY * 12 / 10);
//         rate = cdp.baseInterestRate();
//         assertEq(rpow(rate,1 years),RAY * 12 / 10);
//         rate = cdp.adjustedInterestRate(1);
//         assertEq(rpow(rate,1 years),RAY * 1196 / 1000);
//         rate = cdp.adjustedInterestRate(2);
//         assertEq(rpow(rate,1 years),RAY * 1194 / 1000);
//         rate = cdp.adjustedInterestRate(3);
//         assertEq(rpow(rate,1 years),RAY * 1192 / 1000);
//         rate = cdp.adjustedInterestRate(4);
//         assertEq(rpow(rate,1 years),RAY * 1190 / 1000);
//         rate = cdp.adjustedInterestRate(5);
//         assertEq(rpow(rate,1 years),RAY * 1188 / 1000);
//         assertEq(cdp.term(1), 30 * 86400);
//         assertEq(cdp.term(2), 60 * 86400);
//         assertEq(cdp.term(3), 90 * 86400);
//         assertEq(cdp.term(4), 180 * 86400);
//         assertEq(cdp.term(5), 360 * 86400);

//         cdp.call(abi.encodeWithSelector(cdp.updateCutDown.selector,1,RAY /10));
//         rate = cdp.adjustedInterestRate(1);
//         assertEq(rpow(rate,1 years),RAY * 11 / 10);

//         bool tempBool;
//         //Only allowed enumeration values can modify parameters
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateCutDown.selector,0,RAY /10));
//         assertTrue(!tempBool);
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateCutDown.selector,6,RAY /10));
//         assertTrue(!tempBool);
//         //The parameters can't be set below 1.
//         tempBool = cdp.call(abi.encodeWithSelector(cdp.updateCutDown.selector,1,RAY /4));
//         assertTrue(!tempBool);
//     }

//     function testTimeLending() public {
//         setup();
//         bool tempBool;
//         tempBool = cdp.call.value(195000000, ASSET_BTC)(abi.encodeWithSelector(cdp.createDepositBorrow.selector,100000000,CDP.CDPType._30DAYS));
//         assertTrue(tempBool);
//         tempBool = cdp.call.value(190000000, ASSET_BTC)(abi.encodeWithSelector(cdp.createDepositBorrow.selector,100000000,CDP.CDPType._30DAYS));
//         assertTrue(!tempBool);

//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._30DAYS);
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,1481964);
//         cdp.repay.value(481964, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,1000000);
//         cdp.repay.value(4000000, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,97000000);
//         assertEq(interest,0);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._60DAYS);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,2957562);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._90DAYS);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,4425809);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._180DAYS);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,8957228);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._360DAYS);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,18519982);
//     }

//     function testRepayPrecisely() public {
//         setup();
//         uint idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType._360DAYS);
//         (uint principal, uint interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,18519982);
//         assertEq(cdp.totalPrincipal(),100000000);
//         assertEq(liquidator.totalDebtPAI(),0);
//         assertEq(liquidator.totalAssetPAI(),0);

//         cdp.repay.value(118519000, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,0);
//         assertEq(interest,0);
//         assertEq(cdp.totalPrincipal(),0);
//         assertEq(liquidator.totalDebtPAI(),0);
//         uint num = 18519000;
//         assertEq(liquidator.totalAssetPAI(),num);


//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.fly(10);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,6);//10
//         assertEq(cdp.totalPrincipal(),100000000);
//         assertEq(liquidator.totalDebtPAI(),0);
//         cdp.repay.value(99999990, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,10 + 6);//14
//         assertEq(interest,0);
//         assertEq(cdp.totalPrincipal(),10 + 6);//16
//         assertEq(liquidator.totalDebtPAI(),0);
//         assertEq(liquidator.totalAssetPAI(),num + 6);//18
//         cdp.repay.value(16, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,0);
//         assertEq(interest,0);
//         assertEq(cdp.totalPrincipal(),0);


//         num = num + 6;
//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.fly(10);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,6);
//         assertEq(cdp.totalPrincipal(),100000000);
//         assertEq(liquidator.totalDebtPAI(),0);
//         cdp.repay.value(100000001, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,0);
//         assertEq(interest,0);
//         assertEq(cdp.totalPrincipal(),0);
//         assertEq(liquidator.totalDebtPAI(),0);
//         assertEq(liquidator.totalAssetPAI(),num + 1);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.fly(3800);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,2197);
//         cdp.repay.value(100000116, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,0);
//         assertEq(interest,0);

//         idx = cdp.createDepositBorrow.value(200000000, ASSET_BTC)(100000000,CDP.CDPType.CURRENT);
//         cdp.fly(3800);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,100000000);
//         assertEq(interest,2197);
//         cdp.repay.value(100000115, ASSET_PAI)(idx);
//         (principal, interest) = cdp.debtOfCDP(idx);
//         assertEq(principal,2082);
//         assertEq(interest,0);
//     }

// }