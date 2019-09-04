pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract FakePerson is Template {
    function() public payable {}

    function callBuyCDP(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("buyCDP(uint256)"));
        bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
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
        cdp.setAssetCollateral(ASSET_BTC);

        oracle.updatePrice(ASSET_BTC, RAY);

        paiIssuer.mint(1000000000000, this);
        btcIssuer.mint(1000000000000, this);
    }
}