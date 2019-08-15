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

        paiIssuer.mint(100000000000, this);
        btcIssuer.mint(10000000000, this);

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


}