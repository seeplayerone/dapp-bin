pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../cdp.sol";
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

contract CDPTest is Template, DSTest, DSMath {
    TimefliesCDP private cdp;
    Liquidator private liquidator;
    PriceOracle private oracle;
    FakePAIIssuer private paiIssuer;
    FakeBTCIssuer private btcIssuer;

    uint private ASSET_BTC;
    uint private ASSET_PAI;

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

        oracle.updatePrice(ASSET_BTC, RAY * 10);

        paiIssuer.mint(100000000000, this);
        btcIssuer.mint(10000000000, this);

    }

    //// test when there is enough BTC deposit
    function testBorrowGovernanceFee() public {
        setup();
        uint idx = cdp.createCDP();
        cdp.deposit.value(100000000, ASSET_BTC)(idx);
        cdp.updateGovernanceFee(1000000003000000000000000000);
        cdp.borrow(idx, 100000000);
        cdp.fly(1 days);
        assertEq(100025920, cdp.debtOfCDPwithGovernanceFee(idx));
    }
    
}