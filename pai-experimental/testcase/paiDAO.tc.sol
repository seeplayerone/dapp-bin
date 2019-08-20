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
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_person.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract FakePerson is Template {
    function() public payable {}

    function callAnyMethod(bytes4 _func, bytes _param, address _addr, uint _amout, uint96 _assetGlobalId) public returns (bool) {
        address tempAddress = _addr;
        uint paramLength = _param.length;
        uint totalLength = 4 + paramLength;
        uint amount = _amount;
        uint assetGlobalId = _assetGlobalId;

        assembly {
            let p := mload(0x40)
            mstore(p, _func)
            for { let i := 0 } lt(i, paramLength) { i := add(i, 32) } {
                mstore(add(p, add(4,i)), mload(add(add(_param, 0x20), i)))
            }

            let success := call(not(0), tempAddress, amount, assetGlobalId, p, totalLength, 0, 0)

            let size := returndatasize
            returndatacopy(p, 0, size)

            return success
        }
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
        paiDAO = new FakePaiDao("PAIDAO", new address[](0));
        FakePerson p1 = new FakePerson();
        paiDAO.init();
        paiDAO.tempMintPIS(100000000, 0x6674f97041ba5ab1dd0e98e4fa6212ef590fedec95);
        (,ASSET_PIS) = paiDAO.Token(0);

        assertEq(flow.balance(0x6674f97041ba5ab1dd0e98e4fa6212ef590fedec95,ASSET_PIS),100000000);

        bool success = p1.callAnyMethod(0xc717df3b,0x0000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000006674f97042ba5ab1dd0e98e4fa6212ef590fedec95,paiDAO,0,0);
        assertEq(success,true);
    }
}