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

    // function callBuyCDP(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("buyCDP(uint256)"));
    //     bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

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

        paiIssuer.mint(1000000000000, this);
        paiIssuer.mint(1000000000000, financial);

        paiIssuer2.mint(1000000000000, this);
        paiIssuer2.mint(1000000000000, financial);
    }

    function testSetRate() public {
        assertEq(tdc.baseInterestRate(), RAY / 5);
        tdc.updateBaseInterestRate(RAY / 10);
        assertEq(tdc.baseInterestRate(), RAY / 10);
        assertEq(tdc.floatUp(0),RAY * 4 / 1000);
        assertEq(tdc.floatUp(1),RAY * 6 / 1000);
        assertEq(tdc.floatUp(2),RAY * 8 / 1000);
        assertEq(tdc.floatUp(3),RAY * 10 / 1000);
        assertEq(tdc.floatUp(4),RAY * 12 / 1000);


    }
}