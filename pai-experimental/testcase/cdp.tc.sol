pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../cdp.sol";
// import "../fake_btc_issuer.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/cdp.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/fake_btc_issuer.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/settlement.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

/// this contract is used to simulate `time flies` to test governance fees and stability fees accurately
contract TestTimeflies is DSNote {
    uint256  _era;

    constructor() public {
        _era = now;
    }

    function era() public view returns (uint256) {
        return _era == 0 ? now : _era;
    }

    function fly(uint age) public note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract TimefliesCDP is CDP, TestTimeflies {
    constructor(address _issuer, address _oracle, address _liquidator)
        CDP(_issuer, _oracle, _liquidator)
        public 
    {

    }
}

contract TestBase is Template, DSTest, DSMath {
    TimefliesCDP internal cdp;
    Liquidator internal liquidator;
    PriceOracle internal oracle;
    FakePAIIssuer internal paiIssuer;
    FakeBTCIssuer internal btcIssuer;

    uint internal ASSET_BTC;
    uint internal ASSET_PAI;

    function() public payable {

    }

    function setup() public {
        oracle = new PriceOracle();

        paiIssuer = new FakePAIIssuer();
        paiIssuer.init("sb");
        ASSET_PAI = paiIssuer.getAssetType();

        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("sb2");
        ASSET_BTC = btcIssuer.getAssetType();

        liquidator = new Liquidator(oracle, paiIssuer);
        liquidator.setAssetBTC(ASSET_BTC);

        cdp = new TimefliesCDP(paiIssuer, oracle, liquidator);
        cdp.setAssetBTC(ASSET_BTC);

        oracle.updatePrice(ASSET_BTC, RAY);

        paiIssuer.mint(1000000000000, this);
        btcIssuer.mint(1000000000000, this);
    }
}

contract CDPTest is TestBase {

    function testBasic() public  {
        setup();
        assertEq(cdp.totalCollateral(), 0);
        assertEq(cdp.totalDebt(), 0);

        uint idx = cdp.createCDP();
        assertEq(cdp.collateralOfCDP(idx), 0);
        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(cdp.debtOfCDPwithGovernanceFee(idx), 0);

        cdp.deposit.value(100000000, ASSET_BTC)(idx);    
        assertEq(cdp.totalCollateral(), 100000000);
        assertEq(cdp.collateralOfCDP(idx), 100000000);

        cdp.deposit.value(100000000, ASSET_BTC)(idx);    
        assertEq(cdp.totalCollateral(), 200000000);
        assertEq(cdp.collateralOfCDP(idx), 200000000);        

        cdp.withdraw(idx, 100000000);
        assertEq(cdp.totalCollateral(), 100000000);
        assertEq(cdp.collateralOfCDP(idx), 100000000);

        cdp.withdraw(idx, 100000000);        
        assertEq(cdp.totalCollateral(), 0);
        assertEq(cdp.collateralOfCDP(idx), 0);

        cdp.closeCDPRecord(idx);
    }

    function testTransferCDP() public {
        setup();
        uint idx = cdp.createCDP();
        assertEq(cdp.ownerOfCDP(idx), this);

        cdp.transferCDPOwnership(idx, 0x123);
        assertEq(cdp.ownerOfCDP(idx), 0x123);
    }

    /// -32000:fvm: execution reverted
    function testTransferCDPFail() public {
        setup();
        uint idx = cdp.createCDP();
        cdp.transferCDPOwnership(idx, 0x123);

        cdp.transferCDPOwnership(idx, 0x456);
    }
    
    function testSetLiquidationRatio() public {
        setup();
        cdp.updateLiquidationRatio(1130000000000000000000000000);
        assertEq(cdp.getLiquidationRatio(), 1130000000000000000000000000);
    }

    function testSetLiquidationRatioFail() public {
        setup();
        cdp.updateLiquidationRatio(990000000000000000000000000);
        assertEq(cdp.getLiquidationRatio(), 990000000000000000000000000);
    }

    function testSetLiquidationPenalty() public {
        setup();
        cdp.updateLiquidationPenalty(1500000000000000000000000000);
        assertEq(cdp.getLiquidationPenalty(), 1500000000000000000000000000);
    }

    function testSetLiquidationPenaltyFail() public {
        setup();
        cdp.updateLiquidationPenalty(990000000000000000000000000);
        assertEq(cdp.getLiquidationPenalty(), 990000000000000000000000000);
    }

    function testSetDebtCeiling() public {
        setup();
        cdp.updateDebtCeiling(1000000000000);
        assertEq(cdp.getDebtCeiling(), 1000000000000);
    }

    function testSetPriceOracle() public {
        setup();
        cdp.setPriceOracle(PriceOracle(0x123));
        assertEq(cdp.getPriceOracle(), 0x123);
    }

    function testBorrow() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        assertEq(cdp.debtOfCDP(idx), 0);
        cdp.borrow(idx, 100000000);
        assertEq(cdp.debtOfCDP(idx), 100000000);
    }

    /// -32000:fvm: execution reverted
    function testBorrowFail() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 200000000);
    }


    function testRepay() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        assertEq(cdp.debtOfCDP(idx), 0);
        cdp.borrow(idx, 100000000);
        assertEq(cdp.debtOfCDP(idx), 100000000);
        cdp.repay.value(50000000, ASSET_PAI)(idx);
        assertEq(cdp.debtOfCDP(idx), 50000000);
    }

    function testUnsafe() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 90000000);
        assertTrue(cdp.safe(idx));
        oracle.updatePrice(ASSET_BTC, RAY / 2);
        assertTrue(!cdp.safe(idx));
    }

    function testLiquidationCase1() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);   
        cdp.borrow(idx, 50000000);      
        oracle.updatePrice(ASSET_BTC, RAY / 4);

        assertEq(liquidator.totalCollateralBTC(), 0);
        cdp.liquidate(idx);
        assertEq(liquidator.totalCollateralBTC(), 100000000);
    }

    function testLiquidationCase2() public {
        setup();
        cdp.updateLiquidationRatio(2000000000000000000000000000);     
        cdp.updateLiquidationPenalty(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);   

        cdp.borrow(idx, 40000000);      
        assertTrue(cdp.safe(idx));
        oracle.updatePrice(ASSET_BTC, RAY / 2);
        assertTrue(!cdp.safe(idx));

        assertEq(cdp.totalDebt(), 40000000);
        assertEq(cdp.debtOfCDP(idx), 40000000);
        assertEq(liquidator.totalCollateralBTC(), 0);
        assertEq(liquidator.totalDebtPAI(), 0);

        cdp.liquidate(idx);
        assertEq(cdp.totalDebt(), 0);
        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(liquidator.totalCollateralBTC(), 80000000);
        assertEq(liquidator.totalDebtPAI(), 40000000);

        uint emm = flow.balance(this, ASSET_BTC);
        cdp.withdraw(idx, 10000000);

        assertEq(flow.balance(this, ASSET_BTC) - emm, 10000000);
    }

    function testDeposit() public {
        setup();
        assertEq(cdp.totalCollateral(), 0);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);    
        assertEq(cdp.totalCollateral(), 100000000);
    }

    function testWithdraw() public {
        setup();
        cdp.updateLiquidationRatio(2000000000000000000000000000);     
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);   
        cdp.borrow(idx, 40000000); 

        uint emm = flow.balance(this, ASSET_BTC);
        cdp.withdraw(idx, 20000000);

        assertEq(flow.balance(this, ASSET_BTC) - emm, 20000000);      
    }

    /// -32000:fvm: execution reverted
    function testWithdrawFail() public {
        setup();
        cdp.updateLiquidationRatio(2000000000000000000000000000);     
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);   
        cdp.borrow(idx, 40000000); 

        uint emm = flow.balance(this, ASSET_BTC);
        cdp.withdraw(idx, 30000000);
    }

    /// TODO implement debt ceiling in cdp.sol
    function testBorrowFailOverDebtCeiling() public {

    }

    /// TODO implement debt ceiling in cdp.sol
    function testDebtCeiling() public {

    }

    function testCloseCDP() public {
        setup();
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 50000000);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        cdp.closeCDPRecord.value(60000000, ASSET_PAI)(idx);

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 50000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 100000000);
    }

    function testCloseCDPFail() public {
        setup();
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 50000000);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        cdp.closeCDPRecord.value(40000000, ASSET_PAI)(idx);
    }

}
 
contract StabilityFeeTest is TestBase {
    function testEraInit() public {
        setup();
        assertEq(uint(cdp.era()), now);
    }

    function testEraFlies() public {
        setup();
        cdp.fly(20);
        assertEq(uint(cdp.era()), now + 20);
    }

    function feeSetup() public returns (uint) {
        setup();
        oracle.updatePrice(ASSET_BTC, RAY * 10);
        cdp.updateStabilityFee(1000000564701133626865910626);
        cdp.updateLiquidationRatio(RAY);
        uint idx = cdp.createCDP();
        cdp.deposit.value(10000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 10000000000);

        return idx;
    }

    function testStabilityFeeFlies() public {
        uint idx = feeSetup();
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 11025000000);
    }

    function testTotalDebtFlies() public {
        feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        cdp.fly(1 days);
        cdp.updateRates();
        assertEq(cdp.totalDebt(), 10500000000);
    }

    function testLiquidatorIncome1() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 0);

        cdp.fly(1 days);

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);        
    }

    function testLiquidatorIncome2() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 0);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);         

        cdp.repay.value(500000000, ASSET_PAI)(idx);

        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);         

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 1000000000);                        
    }

    function testLiquidatorImcome3() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 0);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);         

        cdp.repay.value(500000000, ASSET_PAI)(idx);

        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);         

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 1000000000);                        

        cdp.repay.value(500000000, ASSET_PAI)(idx);

        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 1000000000);         

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 1500000000);                        

    }

    function testFeeBorrow() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);

        cdp.borrow(idx, 10000000000);
        assertEq(cdp.totalDebt(), 20500000000);
        assertEq(cdp.debtOfCDP(idx), 20500000000);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 21525000000);
        assertEq(cdp.debtOfCDP(idx), 21525000000);
    }

    function testFeeRepay() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);

        cdp.repay.value(5000000000, ASSET_PAI)(idx);
        assertEq(cdp.totalDebt(), 5500000000);
        assertEq(cdp.debtOfCDP(idx), 5500000000);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 5775000000);
        assertEq(cdp.debtOfCDP(idx), 5775000000);        
    }

    function testFeeSafe() {
        uint idx = feeSetup();
        oracle.updatePrice(ASSET_BTC, RAY);
        assertTrue(cdp.safe(idx));
        cdp.fly(1 days);
        assertTrue(!cdp.safe(idx));
    }

    function testFeeLiquidate() {
        uint idx = feeSetup();
        oracle.updatePrice(ASSET_BTC, RAY);
        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        cdp.liquidate(idx);
        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(liquidator.totalDebtPAI(), 10000000000);        
    }

    function testFeeLiquidateRounding() {
        uint idx = feeSetup();
        oracle.updatePrice(ASSET_BTC, RAY);
        cdp.updateLiquidationRatio(1500000000000000000000000000);
        cdp.updateLiquidationPenalty(1400000000000000000000000000);
        cdp.updateStabilityFee(1000000001547126000000000000);
        for (uint i=0; i<=50; i++) {
            cdp.fly(10);
        }
        uint256 debtAfterFly = rmul(10000000000, rpow(cdp.getStabilityFee(), 510));
        assertEq(cdp.debtOfCDP(idx), debtAfterFly);
        cdp.liquidate(idx);
        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(liquidator.totalDebtPAI(), 10000000000);
    }
}

contract GovernanceFeeTest is TestBase {
    function feeSetup() public returns (uint) {
        setup();
        oracle.updatePrice(ASSET_BTC, RAY * 10);
        cdp.updateGovernanceFee(1000000564701133626865910626);
        cdp.updateLiquidationRatio(RAY);
        uint idx = cdp.createCDP();
        cdp.deposit.value(10000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 10000000000);

        return idx;
    }

    function testFeeSetup() public {
        feeSetup();
        assertEq(cdp.updateAndFetchRates1(), RAY);
        assertEq(cdp.updateAndFetchRates2(), RAY);
    }

    function testFeeFly() public {
        feeSetup();
        cdp.fly(1 days);
        assertEq(cdp.updateAndFetchRates1(), RAY);
        assertEq(cdp.updateAndFetchRates2(), RAY * 105 / 100);
    }

    function testFeeIce() public {
        uint idx = feeSetup();

        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 0);

        cdp.fly(1 days);

        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);        
    }

    function testFeeBorrow() public {
        uint idx = feeSetup(); 

        cdp.fly(1 days);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);

        cdp.borrow(idx, 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);

        cdp.fly(1 days);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 1525000000);
    }

    function testFeeRepay() public {
        uint idx = feeSetup(); 

        cdp.fly(1 days);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);

        cdp.repay.value(5250000000, ASSET_PAI)(idx);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 250000000);

        cdp.fly(1 days);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 512500000);
    }

    function testFeeRepayAll() public {
        uint idx = feeSetup(); 

        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);

        uint emm = flow.balance(this, ASSET_PAI);
        cdp.repay.value(20000000000, ASSET_PAI)(idx);
        assertEq(emm - flow.balance(this, ASSET_PAI), 10500000000);

        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 0);
    }

    function testFeeCloseCDP() public {
        uint idx = feeSetup(); 

        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 500000000);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        cdp.closeCDPRecord.value(20000000000, ASSET_PAI)(idx);
        assertEq(emm1 - flow.balance(this, ASSET_PAI), 10500000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 10000000000);        
    }

}

contract DoubleFeeTest is TestBase {
    function feeSetup() public returns (uint) {
        setup();
        oracle.updatePrice(ASSET_BTC, RAY * 10);
        cdp.updateStabilityFee(1000000564701133626865910626);
        cdp.updateGovernanceFee(1000000564701133626865910626);
        cdp.updateLiquidationRatio(RAY);
        uint idx = cdp.createCDP();
        cdp.deposit.value(10000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 10000000000);

        return idx;
    }    

    function testDoubleFeeFly() {
        feeSetup();
        cdp.fly(1 days);
        assertEq(cdp.updateAndFetchRates1(), RAY * 105 / 100);
        assertEq(cdp.updateAndFetchRates2(), RAY * 11025 / 10000);        
    }

    function testDoubleFeeIce() {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 0);
        assertEq(liquidator.totalAssetPAI(), 0);

        cdp.fly(1 days);
        cdp.updateRates();

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);  
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 525000000);               
    }

    function testDoubleFeeBorrow() {
        uint idx = feeSetup();
        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        cdp.borrow(idx, 10000000000);
        assertEq(cdp.debtOfCDP(idx), 20500000000);
    }

    function testDoubleFeeRepay() {
        uint idx = feeSetup();

        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 525000000);               

        cdp.repay.value(5512500000, ASSET_PAI)(idx);

        assertEq(cdp.debtOfCDP(idx), 5250000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 262500000);               

        /// all stability fees + half governance fees
        assertEq(liquidator.totalAssetPAI(), 762500000);
    }

    function testDoubleFeeRepayAll() {
        uint idx = feeSetup();

        cdp.fly(1 days);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 525000000);               

        uint emm = flow.balance(this, ASSET_PAI);
        cdp.repay.value(20000000000, ASSET_PAI)(idx);
        assertEq(emm - flow.balance(this, ASSET_PAI), 11025000000);

        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(sub(cdp.debtOfCDPwithGovernanceFee(idx), cdp.debtOfCDP(idx)), 0);               

        assertEq(liquidator.totalAssetPAI(), 1025000000);
    }
}

contract LiquidationPenaltyTest is TestBase {
    function penaltySetup() public returns (uint) {
        setup();
        oracle.updatePrice(ASSET_BTC, RAY);
        cdp.updateLiquidationRatio(RAY * 2);

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 1000000000);

        return idx;
    }

    function testPenaltyCase1() {
        uint idx = penaltySetup();
    
        cdp.updateLiquidationRatio(RAY * 21 / 10);
        cdp.updateLiquidationPenalty(RAY * 15 / 10);

        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 500000000);
    }

    function testPenaltyCase2() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY * 15 / 10);
        oracle.updatePrice(ASSET_BTC, RAY * 8 / 10);

        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 125000000);
    }

    function testPenaltyParity() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY * 15 / 10);
        oracle.updatePrice(ASSET_BTC, RAY * 5 / 10);

        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 0);
    }

    function testPenaltyUnder() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY * 15 / 10);
        oracle.updatePrice(ASSET_BTC, RAY * 4 / 10);

        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 0);
    }

    function testSettlementWithPenalty() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY * 15 / 10);
        
        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.terminate();

        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 1000000000);
    }

    function testSettlementWithoutPenalty() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY);
        
        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.terminate();

        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 1000000000);
    }
}

contract LiquidationTest is TestBase {
    function liquidationSetup() {
        setup();   
        oracle.updatePrice(ASSET_BTC, RAY);
        cdp.updateLiquidationRatio(RAY);
        cdp.updateLiquidationPenalty(RAY);
    }

    function liq(uint idx) internal returns (uint256) {
        uint256 collateralValue = cdp.collateralOfCDP(idx);
        uint256 debtValue = rmul(cdp.debtOfCDP(idx), cdp.getLiquidationRatio()); 
        return adiv(debtValue, collateralValue);
    }

    function collat(uint idx) internal returns (uint256) {
        uint256 collateralValue = rmul(cdp.collateralOfCDP(idx), oracle.getPrice(ASSET_BTC));
        uint256 debtValue = cdp.debtOfCDP(idx);
        return adiv(collateralValue, debtValue);
    }

    function testLiq() public {
        liquidationSetup();
        oracle.updatePrice(ASSET_BTC, RAY * 2);

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 1000000000);

        cdp.updateLiquidationRatio(RAY);
        assertEq(liq(idx), ASI);

        cdp.updateLiquidationRatio(RAY * 3 / 2);
        assertEq(liq(idx), ASI * 3 / 2);

        oracle.updatePrice(ASSET_BTC, RAY * 6);
        assertEq(liq(idx), ASI * 3 / 2);

        cdp.borrow(idx, 3000000000);
        assertEq(liq(idx), ASI * 6);

        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        assertEq(liq(idx), ASI * 3);
    }

    function testCollat() {
        liquidationSetup();
        oracle.updatePrice(ASSET_BTC, RAY * 2);

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 1000000000);
        assertEq(collat(idx), ASI * 2);

        oracle.updatePrice(ASSET_BTC, RAY * 4);
        assertEq(collat(idx), ASI * 4);

        cdp.borrow(idx, 1500000000);
        assertEq(collat(idx), ASI * 8 / 5);

        oracle.updatePrice(ASSET_BTC, RAY * 5);
        cdp.withdraw(idx, 500000000);
        assertEq(collat(idx), ASI);

        oracle.updatePrice(ASSET_BTC, RAY * 4);
        assertEq(collat(idx), ASI * 4 / 5);

        cdp.repay.value(900000000, ASSET_PAI)(idx);
        assertEq(collat(idx), ASI * 5 / 4);
    }

    function testLiquidationCase1() {
        liquidationSetup();
        cdp.updateLiquidationRatio(RAY * 3 / 2);
        oracle.updatePrice(ASSET_BTC, RAY * 2);
        liquidator.setDiscount(RAY);

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);

        oracle.updatePrice(ASSET_BTC, RAY * 3);     
        cdp.borrow(idx, 1600000000);
        oracle.updatePrice(ASSET_BTC, RAY * 2);

        assertTrue(!cdp.safe(idx));     

        cdp.liquidate(idx);

        assertEq(liquidator.totalCollateralBTC(), 800000000);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        liquidator.buyCollateral.value(400000000, ASSET_PAI)();

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 400000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 200000000);

        oracle.updatePrice(ASSET_BTC, RAY);

        liquidator.buyCollateral.value(600000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 0);
    }

    function testLiquidationCase2() {
        liquidationSetup();
        cdp.updateLiquidationRatio(RAY * 2);
        cdp.updateLiquidationPenalty(RAY * 3 / 2);
        oracle.updatePrice(ASSET_BTC, RAY * 20);
        liquidator.setDiscount(RAY);

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 10000000000);

        oracle.updatePrice(ASSET_BTC, RAY * 15);

        cdp.liquidate(idx);

        assertEq(cdp.debtOfCDP(idx), 0);
        assertEq(cdp.collateralOfCDP(idx), 0);

        assertEq(liquidator.totalDebtPAI(), 10000000000);
        assertEq(liquidator.totalCollateralBTC(), 1000000000);

        idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 5000000000);

        liquidator.buyCollateral.value(15000000000, ASSET_PAI)();
        assertEq(liquidator.totalDebtPAI(), 0);
        assertEq(liquidator.totalCollateralBTC(), 0);      
        assertEq(liquidator.totalAssetPAI(), 5000000000);
    }
}

contract LiquidatorTest is TestBase {
    function liquidatorSetup() public {
        setup();
        liquidator.setDiscount(RAY);
    }

    function testCancelDebt() public {
        liquidatorSetup(); 

        liquidator.addDebt(5000000000);
        paiIssuer.mint(6000000000, liquidator);

        assertEq(liquidator.totalAssetPAI(), 6000000000);
        assertEq(liquidator.totalDebtPAI(), 5000000000);

        liquidator.cancelDebt();
        assertEq(liquidator.totalAssetPAI(), 1000000000);
        assertEq(liquidator.totalDebtPAI(), 0);
    }

    function testBuyCollateral() public {
        liquidatorSetup();

        btcIssuer.mint(5000000000, liquidator);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        liquidator.buyCollateral.value(3000000000, ASSET_PAI)();

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 3000000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 3000000000);
    }

    function testBuyCollateralAll() public {
        liquidatorSetup();

        btcIssuer.mint(5000000000, liquidator);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        liquidator.buyCollateral.value(6000000000, ASSET_PAI)();        

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 5000000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 5000000000);
    }

    function testCancelDebtAfterBuy1() public {
        liquidatorSetup(); 

        liquidator.addDebt(2000000000);
        paiIssuer.mint(1000000000, liquidator);
        btcIssuer.mint(5000000000, liquidator);

        liquidator.buyCollateral.value(1500000000, ASSET_PAI)();        

        assertEq(liquidator.totalAssetPAI(), 500000000);
        assertEq(liquidator.totalDebtPAI(), 0);
    }

    function testCancelDebtAfterBuy2() public {
        liquidatorSetup(); 

        liquidator.addDebt(2000000000);
        paiIssuer.mint(1000000000, liquidator);
        btcIssuer.mint(5000000000, liquidator);

        liquidator.buyCollateral.value(500000000, ASSET_PAI)();        

        assertEq(liquidator.totalAssetPAI(), 0);
        assertEq(liquidator.totalDebtPAI(), 500000000);
    }
    
    function testDiscountBuyPartial() public {
        liquidatorSetup();

        liquidator.setDiscount(RAY * 9 / 10);
        oracle.updatePrice(ASSET_BTC, RAY * 2);

        btcIssuer.mint(1000000000, liquidator);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        liquidator.buyCollateral.value(900000000, ASSET_PAI)();

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 900000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 500000000);

        assertEq(liquidator.totalAssetPAI(), 900000000);
        assertEq(liquidator.totalCollateralBTC(), 500000000);
    }

    function testDiscountBuyAll() public {
        liquidatorSetup();

        liquidator.setDiscount(RAY * 9 / 10);
        oracle.updatePrice(ASSET_BTC, RAY * 2);

        btcIssuer.mint(1000000000, liquidator);

        uint emm1 = flow.balance(this, ASSET_PAI);
        uint emm2 = flow.balance(this, ASSET_BTC);

        liquidator.buyCollateral.value(9000000000, ASSET_PAI)();

        assertEq(emm1 - flow.balance(this, ASSET_PAI), 1800000000);
        assertEq(flow.balance(this, ASSET_BTC) - emm2, 1000000000);

        assertEq(liquidator.totalAssetPAI(), 1800000000);
        assertEq(liquidator.totalCollateralBTC(), 0);
    }
}

contract SettlementTest is TestBase {
    Settlement settlement;

    function settlementSetup() public {
        setup();
        oracle.updatePrice(ASSET_BTC, RAY);
        cdp.updateLiquidationRatio(RAY * 2);
        cdp.updateLiquidationPenalty(RAY * 3 / 2);
        liquidator.setDiscount(RAY);

        settlement = new Settlement(oracle, cdp, liquidator);
    }

    function testSettlementNormal() public {
        settlementSetup();

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();

        assertTrue(!cdp.readyForPhaseTwo());
        cdp.liquidate(idx);
        assertEq(liquidator.totalCollateralBTC(), 500000000);
        assertEq(liquidator.totalDebtPAI(), 500000000);
        assertTrue(cdp.readyForPhaseTwo());
        assertEq(cdp.totalCollateral(), 1500000000);
        assertEq(cdp.totalDebt(), 0);

        cdp.withdraw(idx, 500000000);
        assertEq(cdp.totalCollateral(), 1000000000);
        assertEq(cdp.totalDebt(), 0);

        settlement.terminatePhaseTwo();
        cdp.withdraw(idx, 500000000);
        assertEq(cdp.totalCollateral(), 500000000);
        assertEq(cdp.totalDebt(), 0);

        liquidator.buyCollateral.value(500000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 0);
        assertEq(liquidator.totalDebtPAI(), 0);
    }

    function testSettlementMultipleCDPOverCollateral() public {
        settlementSetup();
        
        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        uint idx2 = cdp.createCDP();
        cdp.deposit.value(3000000000, ASSET_BTC)(idx2);
        cdp.borrow(idx2, 1000000000);

        uint idx3 = cdp.createCDP();
        cdp.deposit.value(5000000000, ASSET_BTC)(idx3);
        cdp.borrow(idx3, 2000000000);

        assertEq(cdp.totalCollateral(), 10000000000);
        assertEq(cdp.totalDebt(), 3500000000);

        oracle.updatePrice(ASSET_BTC, RAY * 2);
        assertTrue(cdp.safe(idx));
        assertTrue(cdp.safe(idx2));
        assertTrue(cdp.safe(idx3));

        settlement.terminatePhaseOne();

        cdp.liquidate(idx2);
        assertEq(liquidator.totalCollateralBTC(), 500000000);
        assertEq(liquidator.totalDebtPAI(), 1000000000);      

        assertTrue(!cdp.readyForPhaseTwo());

        cdp.quickLiquidate(2);
        assertEq(liquidator.totalCollateralBTC(), 750000000);
        assertEq(liquidator.totalDebtPAI(), 1500000000);      

        assertTrue(!cdp.readyForPhaseTwo());

        cdp.quickLiquidate(3);
        assertEq(liquidator.totalCollateralBTC(), 1750000000);
        assertEq(liquidator.totalDebtPAI(), 3500000000);    

        assertTrue(cdp.totalDebt() == 0);
        assertEq(cdp.collateralOfCDP(idx), 1750000000);
        assertEq(cdp.collateralOfCDP(idx2), 2500000000);
        assertEq(cdp.collateralOfCDP(idx3), 4000000000);
        assertTrue(cdp.readyForPhaseTwo());

        settlement.terminatePhaseTwo();

        liquidator.buyCollateral.value(3500000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 0);
        assertEq(liquidator.totalDebtPAI(), 0);    
    }

    function testSettlementMultipleCDPUnderCollateral() public {
        settlementSetup();
        
        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        uint idx2 = cdp.createCDP();
        cdp.deposit.value(3000000000, ASSET_BTC)(idx2);
        cdp.borrow(idx2, 1000000000);

        uint idx3 = cdp.createCDP();
        cdp.deposit.value(5000000000, ASSET_BTC)(idx3);
        cdp.borrow(idx3, 2000000000);

        assertEq(cdp.totalCollateral(), 10000000000);
        assertEq(cdp.totalDebt(), 3500000000);

        oracle.updatePrice(ASSET_BTC, RAY / 10);
        assertTrue(!cdp.safe(idx));
        assertTrue(!cdp.safe(idx2));
        assertTrue(!cdp.safe(idx3));

        settlement.terminatePhaseOne();

        cdp.liquidate(idx2);
        assertEq(liquidator.totalCollateralBTC(), 3000000000);
        assertEq(liquidator.totalDebtPAI(), 1000000000);      

        assertTrue(!cdp.readyForPhaseTwo());

        cdp.quickLiquidate(2);
        assertEq(liquidator.totalCollateralBTC(), 5000000000);
        assertEq(liquidator.totalDebtPAI(), 1500000000);      

        assertTrue(!cdp.readyForPhaseTwo());

        cdp.quickLiquidate(3);
        assertEq(liquidator.totalCollateralBTC(), 10000000000);
        assertEq(liquidator.totalDebtPAI(), 3500000000);    

        assertTrue(cdp.totalDebt() == 0);
        assertEq(cdp.collateralOfCDP(idx), 0);
        assertEq(cdp.collateralOfCDP(idx2), 0);
        assertEq(cdp.collateralOfCDP(idx3), 0);
        assertTrue(cdp.readyForPhaseTwo());

        settlement.terminatePhaseTwo();

        liquidator.buyCollateral.value(3500000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 0);
        assertEq(liquidator.totalDebtPAI(), 0);    
    }

    function testSettlementPhaseOneBuyFromLiquidatorFail() {
        settlementSetup();        

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        assertTrue(cdp.safe(idx));
        oracle.updatePrice(ASSET_BTC, RAY / 2);

        assertTrue(!cdp.safe(idx));
        cdp.liquidate(idx);

        assertEq(liquidator.totalCollateralBTC(), 1000000000);
        assertEq(liquidator.totalDebtPAI(), 500000000);    

        liquidator.buyCollateral.value(100000000, ASSET_PAI)();

        assertEq(liquidator.totalCollateralBTC(), 800000000);
        assertEq(liquidator.totalDebtPAI(), 400000000);    

        settlement.terminatePhaseOne();
        /// cause revert
        liquidator.buyCollateral.value(100000000, ASSET_PAI)();

        settlement.terminatePhaseTwo();
        liquidator.buyCollateral.value(100000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 600000000);
        assertEq(liquidator.totalDebtPAI(), 300000000);    

    }

    function testSettlementPhaseTwoBuyFromLiquidator() {
        settlementSetup();        

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        assertTrue(cdp.safe(idx));
        oracle.updatePrice(ASSET_BTC, RAY / 2);

        assertTrue(!cdp.safe(idx));
        cdp.liquidate(idx);

        assertEq(liquidator.totalCollateralBTC(), 1000000000);
        assertEq(liquidator.totalDebtPAI(), 500000000);    

        liquidator.buyCollateral.value(100000000, ASSET_PAI)();

        assertEq(liquidator.totalCollateralBTC(), 800000000);
        assertEq(liquidator.totalDebtPAI(), 400000000);    

        settlement.terminatePhaseOne();

        settlement.terminatePhaseTwo();
        liquidator.buyCollateral.value(100000000, ASSET_PAI)();
        assertEq(liquidator.totalCollateralBTC(), 600000000);
        assertEq(liquidator.totalDebtPAI(), 300000000);    

    }

    function testSettlementDepositFail() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();

        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
    }

    function testSettlementDepositCompare() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(1000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        cdp.deposit.value(1000000000, ASSET_BTC)(idx);        
    }

    function testSettlementBorrowFail() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();

        cdp.borrow(idx, 500000000);
    }

    function testSettlementBorrowCompare() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        cdp.borrow(idx, 500000000);
    }

    function testSettlementRepayFail() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();

        cdp.repay.value(500000000, ASSET_PAI)(idx);
    }

    function testSettlementRepayCompare() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        cdp.repay.value(500000000, ASSET_PAI)(idx);
    }

    function testSettlementPhaseOneWithdraw() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);

        settlement.terminatePhaseOne();

        cdp.withdraw(idx, 1000000000);
    }

    function testSettlementPhaseTwoWithdraw() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);

        settlement.terminatePhaseOne();
        settlement.terminatePhaseTwo();

        cdp.withdraw(idx, 1000000000);
    }

    function testDirectPhaseTwoFail() {
        settlementSetup();     

        settlement.terminatePhaseTwo();
    } 

    function testPhaseTwoNotReadyFail() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();
        settlement.terminatePhaseTwo();
    }

    function testPhaseTwoReady() {
        settlementSetup();     

        uint idx = cdp.createCDP();
        cdp.deposit.value(2000000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 500000000);

        settlement.terminatePhaseOne();

        cdp.liquidate(idx);

        settlement.terminatePhaseTwo();
    }

    function testSettlementUpdateOracleFail() {
        settlementSetup();     

        settlement.terminatePhaseOne();

        oracle.updatePrice(ASSET_BTC, 1);
    }

    function testSettlementUpdateOracleCompare() {
        settlementSetup();     

        oracle.updatePrice(ASSET_BTC, 1);
    }

}