pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../cdp.sol";
// import "../fake_btc_issuer.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/mctest.sol";
// import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";
// import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";
// import "github.com/evilcc2018/dapp-bin/pai-experimental/settlement.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO() public returns (address) {
        return (new FakePaiDao("PAIDAO", new address[](0)));
    }

    function callInit(address paidao) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("init()"));
        bool result = FakePaiDao(paidao).call(methodId);
        return result;
    }

    function callConfigFunc(address paidao, string _function, address _address, uint8 _opMode) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("configFunc(string,address,uint8)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,_function,_address,_opMode));
        return result;
    }

    function callConfigOthersFunc(address paidao, address _contract, address _caller, string _str, uint8 _opMode) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("configOthersFunc(address,address,string,uint8)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,_contract,_caller,_str,_opMode));
        return result;
    }

    function callTempConfig(address paidao, string _function, address _address, uint8 _opMode) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("tempConfig(string,address,uint8)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,_function,_address,_opMode));
        return result;
    }

    function callTempOthersConfig(address paidao,address _contract, address _caller, string _str, uint8 _op) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("tempOthersConfig(address,address,string,uint8)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,_contract,_caller,_str,_opMode));
        return result;
    }
    
    function callTempMintPIS(address paidao, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("tempMintPIS(uint256,address)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,amount,dest));
        return result;
    }

    function callMintPIS(address paidao, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("mintPIS(uint256,address)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,amount,dest));
        return result;
    }



}

// contract FakePAIIssuer is PAIIssuer {
//     constructor() public {
//         templateName = "Fake-Template-Name-For-Test";
//     }
// }


contract FakePaiDao is PAIDAO {
    constructor(string _organizationName, address[] _members)
        PAIDAO(_organizationName, _members)
        public
    {
        templateName = "Fake-Template-Name-For-Test-PaiDao";
    }
}

/// this contract is used to simulate `time flies` to test some method depends on time.
contract TestTimeflies is Template {
    uint256  _era;

    constructor() public {
        _era = block.timestamp;
    }

    function era() public view returns (uint256) {
        return _era == 0 ? block.timestamp : _era;
    }

    function fly(uint age) public {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract TestCase is Template, DSTest, DSMath {
    FakePaiDao internal paiDAO;
    uint96 internal ASSET_PIS;

    function() public payable {

    }

    function testMainContract() public {
        bool tempBool;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();

        ///test init
        paiDAO = FakePaiDao(p1.createPAIDAO());
        assertEq(paiDAO.tempAdmin(),p1);//0
        tempBool = p2.callInit(paiDAO);
        assertTrue(tempBool);//1
        tempBool = p2.callInit(paiDAO);
        assertTrue(!tempBool);//2
        tempBool = p1.callInit(paiDAO);
        assertTrue(!tempBool);//3

        ///test mint
        tempBool = p1.callTempMintPIS(paiDAO,100000000,p3);
        assertTrue(tempBool);//4
        (,ASSET_PIS) = paiDAO.Token(0);
        assertEq(flow.balance(p3,ASSET_PIS),100000000);//5
        tempBool = p2.callTempMintPIS(paiDAO,100000000,p3);
        assertTrue(!tempBool);//6

        ///test auth setting
        tempBool = p3.callMintPIS(paiDAO,100000000,p3);
        assertTrue(!tempBool);//7
        tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,0);
        assertTrue(tempBool);//8
        tempBool = p3.callMintPIS(paiDAO,100000000,p3);
        assertTrue(tempBool);//9
        assertEq(flow.balance(p3,ASSET_PIS),200000000);//10
        tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,1);
        assertTrue(tempBool);//11
        tempBool = p3.callMintPIS(paiDAO,100000000,p3);
        assertTrue(!tempBool);//12

        ///test all by order
        tempBool = p1.callTempConfig(paiDAO,"VOTE",p3,0);
        assertTrue(tempBool);//13
        tempBool = p1.callConfigFunc(paiDAO,"TESTAUTH",p2,0);
        assertTrue(!tempBool);//14
        tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH",p2,0);
        assertTrue(tempBool);//15
        tempBool = paiDAO.canPerform(p2,"TESTAUTH");
        assertTrue(tempBool);//16
        tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH",p2,1);
        assertTrue(tempBool);//17
        tempBool = paiDAO.canPerform(p2,"TESTAUTH");
        assertTrue(!tempBool);//18

        tempBool = p1.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH",0);
        assertTrue(!tempBool);//19
        tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH",0);
        assertTrue(tempBool);//20
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH"));
        assertTrue(tempBool);//21
        tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH",1);
        assertTrue(tempBool);//22
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH"));
        assertTrue(!tempBool);//23

        tempBool = p3.callTempConfig(paiDAO,"TESTAUTH",p4,0);
        assertTrue(!tempBool);//24
        tempBool = p1.callTempConfig(paiDAO,"TESTAUTH",p4,0);
        assertTrue(tempBool);//25
        tempBool = paiDAO.canPerform(p4,"TESTAUTH");
        assertTrue(tempBool);//26
        tempBool = p1.callTempConfig(paiDAO,"TESTAUTH",p4,1);
        assertTrue(tempBool);//27
        tempBool = paiDAO.canPerform(p4,"TESTAUTH");
        assertTrue(!tempBool);//28

        //tempBool = callTempOthersConfig

    }
}