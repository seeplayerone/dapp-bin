pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/tdc.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_financial.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract FakePerson is Template {
    function() public payable {}

    function callDeposit(address tdc, uint8 tdcType, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("deposit(uint8)"));
        bool result = TimefliesTDC(tdc).call.value(amount,id)(abi.encodeWithSelector(methodId,tdcType));
        return result;
    }

    function callWithdraw(address tdc, uint record, uint amount) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("withdraw(uint256,uint256)"));
        bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,record,amount));
        return result;
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

contract TimefliesTDC is TDC, TestTimeflies {
    constructor(address _issuer, address _financial)
        TDC(_issuer, _financial)
        public
    {

    }
}

contract TestTDC is Template, DSTest, DSMath {
    TimefliesTDC internal tdc;
    Financial internal financial;
    FakePAIIssuer internal paiIssuer;
    FakePAIIssuer internal paiIssuer2;

    uint internal ASSET_PAI;
    uint internal FAKE_PAI;

    function() public payable {

    }

    function setup() public {

        paiIssuer = new FakePAIIssuer();
        paiIssuer.init("sb");
        ASSET_PAI = paiIssuer.getAssetType();

        paiIssuer2 = new FakePAIIssuer();
        paiIssuer2.init("sb2");
        FAKE_PAI = paiIssuer2.getAssetType();

        financial = new Financial(paiIssuer);


        tdc = new TimefliesTDC(paiIssuer, financial);

        paiIssuer.mint(100000000, this);
        paiIssuer.mint(100000000, financial);

        paiIssuer2.mint(100000000, this);
        paiIssuer2.mint(100000000, financial);
    }

    function testSetRate() public {
        setup();
        assertEq(tdc.baseInterestRate(), RAY / 5);
        tdc.updateBaseInterestRate(RAY / 10);
        assertEq(tdc.baseInterestRate(), RAY / 10);
        assertEq(tdc.floatUp(0),RAY * 4 / 1000);
        assertEq(tdc.floatUp(1),RAY * 6 / 1000);
        assertEq(tdc.floatUp(2),RAY * 8 / 1000);
        assertEq(tdc.floatUp(3),RAY * 10 / 1000);
        assertEq(tdc.floatUp(4),RAY * 12 / 1000);

        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 4 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 6 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 10 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 12 / 1000);

        tdc.updateFloatUp(TDC.TDCType._30DAYS, RAY * 8 / 1000);
        tdc.updateFloatUp(TDC.TDCType._60DAYS, RAY * 12 / 1000);
        tdc.updateFloatUp(TDC.TDCType._90DAYS, RAY * 16 / 1000);
        tdc.updateFloatUp(TDC.TDCType._180DAYS, RAY * 20 / 1000);
        tdc.updateFloatUp(TDC.TDCType._360DAYS, RAY * 24 / 1000);

        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY/10 + RAY * 8 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY/10 + RAY * 12 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY/10 + RAY * 16 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY/10 + RAY * 20 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY/10 + RAY * 24 / 1000);
    }

    function testDeposit() public {
        setup();
        FakePerson p1 = new FakePerson();
        paiIssuer.mint(100000000, p1);
        paiIssuer2.mint(100000000, p1);
        bool tempBool;
        tempBool = p1.callDeposit(tdc,0,1000,uint96(FAKE_PAI));
        assertTrue(!tempBool);
        tempBool = p1.callDeposit(tdc,0,1000,uint96(ASSET_PAI));
        assertTrue(tempBool);

        (TDC.TDCType tdcType,address owner, uint principal,uint interestRate,uint time) = tdc.TDCRecords(1);
        assertEq(owner,p1);
        assertEq(uint(tdcType),0);
        assertEq(principal,1000);
        assertEq(interestRate, RAY/5 + RAY * 4 / 1000);
        assertEq(time,block.timestamp);
        assertEq(flow.balance(p1,ASSET_PAI), 100000000 - 1000);
    }

    function testWithdraw() public {
        setup();
        uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        (,,uint principal,,) = tdc.TDCRecords(idx);
        assertEq(principal, 10000);
        tdc.withdraw(idx,5000);
        (,,principal,,) = tdc.TDCRecords(idx);
        assertEq(principal, 5000);

        FakePerson p1 = new FakePerson();
        paiIssuer.mint(10000, p1);
        bool tempBool;
        tempBool = p1.callDeposit(tdc,0,10000,uint96(ASSET_PAI));
        assertTrue(tempBool);
        assertEq(flow.balance(p1,ASSET_PAI),0);
        FakePerson p2 = new FakePerson();
        tempBool = p2.callWithdraw(tdc,2,5000);
        assertTrue(!tempBool);
        tempBool = p1.callWithdraw(tdc,2,5000);
        assertTrue(tempBool);
        (,,principal,,) = tdc.TDCRecords(2);
        assertEq(principal, 5000);
        assertEq(flow.balance(p1,ASSET_PAI),5000);
        tempBool = p1.callWithdraw(tdc,2,5001);
        assertTrue(!tempBool);
        tempBool = p1.callWithdraw(tdc,2,5000);
        assertTrue(tempBool);
        (,,principal,,) = tdc.TDCRecords(2);
        assertEq(principal, 0);
        assertEq(flow.balance(p1,ASSET_PAI),10000);
    }

    function testAboutTime() public {
        setup();
        uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        (,,,,uint startTime1) = tdc.TDCRecords(idx);
        uint passedTime = tdc.passedTime(idx);
        assertEq(passedTime,0);
        tdc.fly(100);
        (,,,,uint startTime2) = tdc.TDCRecords(idx);
        assertEq(startTime1,startTime2);
        passedTime = tdc.passedTime(idx);
        assertEq(passedTime,100);

        assertTrue(!tdc.checkMaturity(1000));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(30 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(90 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(180 days);
        assertTrue(tdc.checkMaturity(idx));
        idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
        assertTrue(!tdc.checkMaturity(idx));
        tdc.fly(360 days);
        assertTrue(tdc.checkMaturity(idx));
    }

    function testReturnMoney() public {
        setup();
        uint idx = tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        uint emm = flow.balance(this,ASSET_PAI);
        bool tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
        assertTrue(!tempBool);
        tdc.fly(30 days);
        tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
        assertTrue(tempBool);
        assertEq(flow.balance(this,ASSET_PAI),emm + 10167);
        tempBool = tdc.call(abi.encodeWithSelector(tdc.returnMoney.selector,idx));
        assertTrue(!tempBool);
    }

    function testInterestCalculate() public {
        setup();
        assertEq(tdc.getInterestRate(TDC.TDCType._30DAYS), RAY * 104 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._60DAYS), RAY * 106 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._90DAYS), RAY * 108 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._180DAYS), RAY * 110 / 1000);
        assertEq(tdc.getInterestRate(TDC.TDCType._360DAYS), RAY * 112 / 1000);

        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._30DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._60DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._90DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._180DAYS);
        tdc.deposit.value(10000,ASSET_PAI)(TDC.TDCType._360DAYS);
        tdc.fly(360 days);
        uint emm1 = flow.balance(this,ASSET_PAI);
        uint emm2 = flow.balance(tdc,ASSET_PAI);
        tdc.returnMoney(1);
        assertEq(flow.balance(this,ASSET_PAI) - emm1,10000);
        assertEq(emm2 - flow.balance(tdc,ASSET_PAI),10000);

        assertEq(1 years / 86400,0);




    }
}