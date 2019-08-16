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

    function testTranserCDP() public {
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
    
    /// GETTER missing in cdp.sol
    function testSetConfigs() public {
        setup();
        cdp.updateLiquidationRatio(1130000000000000000000000000);
        cdp.updateLiquidationPenalty(1500000000000000000000000000);
    }

    /// GETTER missing in cdp.sol
    function testSetPriceOracle() public {
        setup();
        cdp.setPriceOracle(PriceOracle(0x123));
    }

    /// -32000:fvm: execution reverted
    function testBorrowFail() public {
        setup();
        cdp.updateLiquidationRatio(1000000000000000000000000000);
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.borrow(idx, 200000000);
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

    function testLiquidatorBonus1() public {
        uint idx = feeSetup();
        assertEq(cdp.totalDebt(), 10000000000);
        assertEq(cdp.debtOfCDP(idx), 10000000000);
        assertEq(liquidator.totalAssetPAI(), 0);

        cdp.fly(1 days);

        assertEq(cdp.totalDebt(), 10500000000);
        assertEq(cdp.debtOfCDP(idx), 10500000000);
        assertEq(liquidator.totalAssetPAI(), 500000000);        
    }

    function testLiquidatorBonus2() public {
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

    function testLiquidatorBonus3() public {
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
        cdp.terminateBusiness();

        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 1000000000);
    }

    function testSettlementWithoutPenalty() {
        uint idx = penaltySetup();

        cdp.updateLiquidationPenalty(RAY);
        
        assertEq(cdp.collateralOfCDP(idx), 2000000000);
        cdp.terminateBusiness();

        cdp.liquidate(idx);
        assertEq(cdp.collateralOfCDP(idx), 1000000000);
    }


}
