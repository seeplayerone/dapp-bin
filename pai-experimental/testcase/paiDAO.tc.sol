pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../cdp.sol";
// import "../fake_btc_issuer.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/settlement.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO() public returns (address) {
        return (new FakePaiDao("PAIDAO", new address[](0)));
    }

    function callTempMintPIS(address _addr, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("tempMintPIS(uint256,address)"));
        bool result = FakePaiDao(_addr).call(methodId,amount,dest);
        return result;
    }

    function callInit(address _addr) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("init()"));
        bool result = FakePaiDao(_addr).call(methodId);
        return result;
    }
            
}


contract FakePaiDao is PAIDAO {
    constructor(string _organizationName, address[] _members)
        PAIDAO(_organizationName, _members)
        public
    {
        templateName = "Fake-Template-Name-For-Test-PaiDao";
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
    FakePaiDao internal paiDAO;
    uint96 internal ASSET_PIS;

    function() public payable {

    }

    function testALL() public {
        bool tempBool;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        //FakePerson p4 = new FakePerson();

        ///test init
        paiDAO = FakePaiDao(p1.createPAIDAO());
        assertEq(paiDAO.tempAdmin(),p1);
        tempBool = p2.callInit(paiDAO);
        assertTrue(tempBool);
        tempBool = p2.callInit(paiDAO);
        assertTrue(!tempBool);
        tempBool = p1.callInit(paiDAO);
        assertTrue(!tempBool);

        ///test mint
        tempBool = p1.callTempMintPIS(paiDAO,100000000,p3);
        assertTrue(tempBool);
        (,ASSET_PIS) = paiDAO.Token(0);
        assertEq(flow.balance(p3,ASSET_PIS),100000000);
        tempBool = p2.callTempMintPIS(paiDAO,100000000,p3);
        assertTrue(!tempBool);

    }
}