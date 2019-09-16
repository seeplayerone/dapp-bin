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
