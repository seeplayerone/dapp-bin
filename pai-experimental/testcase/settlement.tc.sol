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
    Settlement internal settlement;

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

        cdp = new TimefliesCDP(paiDAO,paiIssuer,oracle,liquidator,setting,finance,ASSET_BTC,100000000000);
        admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
        admin.callAddMember(paiDAO,cdp,"PAIMINTER");

        settlement = new Settlement(paiDAO,oracle,cdp,liquidator);
        admin.callAddMember(paiDAO,settlement,"SettlementContract");

        btcIssuer.mint(1000000000000, p1);
        btcIssuer.mint(1000000000000, p2);
        btcIssuer.mint(1000000000000, this);
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

contract SettlementTest is TestBase {
    function settlementSetup() public {
        setup();
        admin.callUpdateLiquidationRatio(cdp, RAY * 2);
        admin.callUpdateLiquidationPenalty(cdp, RAY * 3 / 2);
        liquidator.setDiscount(RAY);
    }

    function testSettlementNormal() public {
        settlementSetup();

        uint idx = cdp.createDepositBorrow.value(2000000000, ASSET_BTC)(500000000,CDP.CDPType.CURRENT);

        bool tempBool = p1.callTerminatePhaseOne(settlement);
        assertTrue(!tempBool);
        tempBool = admin.callTerminatePhaseOne(settlement);
        assertTrue(tempBool);
        // settlement.terminatePhaseOne();

        // assertTrue(!cdp.readyForPhaseTwo());
        // cdp.liquidate(idx);
        // assertEq(liquidator.totalCollateralBTC(), 500000000);
        // assertEq(liquidator.totalDebtPAI(), 500000000);
        // assertTrue(cdp.readyForPhaseTwo());
        // assertEq(cdp.totalCollateral(), 0);
        // assertEq(cdp.totalPrincipal(), 0);

        // settlement.terminatePhaseTwo();
        // liquidator.buyCollateral.value(500000000, ASSET_PAI)();
        // assertEq(liquidator.totalCollateralBTC(), 0);
        // assertEq(liquidator.totalDebtPAI(), 0);
    }

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

}
