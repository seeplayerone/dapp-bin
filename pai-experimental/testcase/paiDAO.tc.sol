pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/mctest.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_vote_manager.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_PISvote_universal.sol";

contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO(string _str) public returns (address) {
        return (new FakePaiDao(_str, new address[](0)));
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

    function callTempOthersConfig(address paidao,address _contract, address _caller, string _str, uint8 _opMode) public returns (bool) {
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

    function callMintPAI(address paidao, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("mintPAI(uint256,address)"));
        bool result = FakePaiDao(paidao).call(abi.encodeWithSelector(methodId,amount,dest));
        return result;
    }

    function callBurn(address paidao, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("burn()"));
        bool result = FakePaiDao(paidao).call.value(amount,id)(abi.encodeWithSelector(methodId));
        return result;
    }

    function callEveryThingIsOk(address paidao) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("everyThingIsOk()"));
        bool result = FakePaiDao(paidao).call(methodId);
        return result;
    }

    function callDeposit(address voteManager, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("deposit()"));
        bool result = PISVoteManager(voteManager).call.value(amount,id)(abi.encodeWithSelector(methodId));
        return result;
    }

    function callWithdraw(address voteManager, uint amount) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("withdraw(uint256)"));
        bool result = PISVoteManager(voteManager).call(abi.encodeWithSelector(methodId,amount));
        return result;
    }

    function callStartVoteTo(
        address voteManager,
        address _voteContract,
         string _subject,
           uint _duration,
        address _targetContract,
         bytes4 _func,
          bytes _param,
           uint _voteNumber
        )
        public returns (bool) {
        bytes4 methodId = bytes4(keccak256("startVoteTo(address,string,uint256,address,bytes4,bytes,uint256)"));
        bool result = PISVoteManager(voteManager).call(abi.encodeWithSelector(methodId,
        _voteContract,_subject,_duration,_targetContract,_func,_param,_voteNumber));
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

    function timeNow() public view returns (uint256) {
        return _era == 0 ? block.timestamp : _era;
    }

    function fly(uint age) public {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract TimefliesVoteU is PISVoteUniversal,TestTimeflies {
    constructor(address _organizationContract)
    PISVoteUniversal(_organizationContract)
    public {
    }
}

contract TestCase is Template, DSTest, DSMath {
    function() public payable {

    }

    function testMainContract() public {
        FakePaiDao paiDAO;
        uint96 ASSET_PIS;
        uint96 ASSET_PAI;
        bool tempBool;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();

        ///test init
        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
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
        tempBool = p1.callConfigFunc(paiDAO,"TESTAUTH1",p2,0);
        assertTrue(!tempBool);//14
        tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH1",p2,0);
        assertTrue(tempBool);//15
        tempBool = paiDAO.canPerform(p2,"TESTAUTH1");
        assertTrue(tempBool);//16
        tempBool = p3.callConfigFunc(paiDAO,"TESTAUTH1",p2,1);
        assertTrue(tempBool);//17
        tempBool = paiDAO.canPerform(p2,"TESTAUTH1");
        assertTrue(!tempBool);//18

        tempBool = p1.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",0);
        assertTrue(!tempBool);//19
        tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",0);
        assertTrue(tempBool);//20
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH2"));
        assertTrue(tempBool);//21
        tempBool = p3.callConfigOthersFunc(paiDAO,p4,p2,"TESTAUTH2",1);
        assertTrue(tempBool);//22
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH2"));
        assertTrue(!tempBool);//23

        tempBool = p3.callTempConfig(paiDAO,"TESTAUTH3",p4,0);
        assertTrue(!tempBool);//24
        tempBool = p1.callTempConfig(paiDAO,"TESTAUTH3",p4,0);
        assertTrue(tempBool);//25
        tempBool = paiDAO.canPerform(p4,"TESTAUTH3");
        assertTrue(tempBool);//26
        tempBool = p1.callTempConfig(paiDAO,"TESTAUTH3",p4,1);
        assertTrue(tempBool);//27
        tempBool = paiDAO.canPerform(p4,"TESTAUTH3");
        assertTrue(!tempBool);//28

        tempBool = p3.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",0);
        assertTrue(!tempBool);//29
        tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",0);
        assertTrue(tempBool);//30
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH4"));
        assertTrue(tempBool);//31
        tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTAUTH4",1);
        assertTrue(tempBool);//32
        tempBool = paiDAO.canPerform(p2, StringLib.strConcat(StringLib.convertAddrToStr(p4),"TESTAUTH4"));
        assertTrue(!tempBool);//33

        /// mintPIS and tempMintPIS are already tested

        tempBool = p1.callMintPAI(paiDAO,100000000,p3);
        assertTrue(!tempBool);//34
        tempBool = p3.callMintPAI(paiDAO,100000000,p3);
        assertTrue(!tempBool);//35
        tempBool = p1.callTempConfig(paiDAO,"ISSURER",p3,0);
        assertTrue(tempBool);//36
        tempBool = p3.callMintPAI(paiDAO,100000003,p3);
        assertTrue(tempBool);//37
        (,ASSET_PAI) = paiDAO.Token(1);
        assertEq(flow.balance(p3,ASSET_PAI),100000003);//38

        uint balance;
        (,,,,,balance) = paiDAO.getAssetInfo(1);
        assertEq(balance,100000003);//39
        (,,,,,balance) = paiDAO.getAssetInfo(0);
        assertEq(balance,200000000);//40
        assertEq(flow.balance(p3,ASSET_PIS),200000000);//41
        p3.callBurn(paiDAO,100000000,ASSET_PIS);
        assertEq(flow.balance(p3,ASSET_PIS),100000000);//42
        (,,,,,balance) = paiDAO.getAssetInfo(0);
        assertEq(balance,100000000);//43
        assertEq(flow.balance(p3,ASSET_PAI),100000003);//44
        p3.callBurn(paiDAO,100000000,ASSET_PAI);
        assertEq(flow.balance(p3,ASSET_PAI),3);//45
        (,,,,,balance) = paiDAO.getAssetInfo(1);
        assertEq(balance,3);//46

        tempBool = p3.callEveryThingIsOk(paiDAO);
        assertTrue(!tempBool);//47
        tempBool = p1.callEveryThingIsOk(paiDAO);
        assertTrue(tempBool);//48
        tempBool = p1.callTempMintPIS(paiDAO,100000000,p3);
        assertTrue(!tempBool);//49
        tempBool = p1.callTempConfig(paiDAO,"TESTDELETE",p4,0);
        assertTrue(!tempBool);//50
        tempBool = p1.callTempOthersConfig(paiDAO,p4,p2,"TESTDELETE",0);
        assertTrue(!tempBool);//51
    }
    
    function testBurn1() public {
        // unrevert is expected
        FakePaiDao paiDAO1;
        FakePaiDao paiDAO2;
        uint96 ASSET_PIS1;
        uint96 ASSET_PIS2;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        paiDAO1 = FakePaiDao(p1.createPAIDAO("DAO1"));
        paiDAO2 = FakePaiDao(p1.createPAIDAO("DAO2"));
        bool tempBool;
        paiDAO1.init();
        paiDAO2.init();
        tempBool = p1.callTempMintPIS(paiDAO1,100000000,p2);
        assertTrue(tempBool); //0
        (,ASSET_PIS1) = paiDAO1.Token(0);
        tempBool = p1.callTempMintPIS(paiDAO2,100000000,p2);
        assertTrue(tempBool); //1
        (,ASSET_PIS2) = paiDAO2.Token(0);
        tempBool = p2.callBurn(paiDAO1,100,ASSET_PIS1);
        assertTrue(tempBool); //2
        tempBool = p2.callBurn(paiDAO2,100,ASSET_PIS2);
        assertTrue(tempBool); //3
        tempBool = p2.callBurn(paiDAO1,100,ASSET_PIS2);
        assertTrue(!tempBool); //4
        tempBool = p2.callBurn(paiDAO2,100,ASSET_PIS1);
        assertTrue(!tempBool); //5
    }

    function testVoteManager() public {
        FakePaiDao paiDAO;
        PISVoteManager voteManager;
        TimefliesVoteU voteContract;
        uint96 ASSET_PIS;
        bool tempBool;
        FakePerson p1 = new FakePerson();

        ///test init
        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        tempBool = p1.callInit(paiDAO);
        tempBool = p1.callTempMintPIS(paiDAO,100000000,p1);
        (,ASSET_PIS) = paiDAO.Token(0);
        voteManager = new PISVoteManager(paiDAO);
        voteContract = new TimefliesVoteU(paiDAO);
        assertEq(voteManager.paiDAO(),paiDAO);//0
        assertEq(uint(voteManager.voteAssetGlobalId()),uint(ASSET_PIS));//1

        ///test deposit && withdraw
        p1.callDeposit(voteManager,40000000,ASSET_PIS);
        assertEq(voteManager.balanceOf(p1),40000000);//2
        assertEq(flow.balance(p1,ASSET_PIS),60000000);//3
        tempBool = p1.callWithdraw(voteManager,60000000);
        assertTrue(!tempBool);//4
        tempBool = p1.callWithdraw(voteManager,40000000);
        assertTrue(tempBool);//5
        assertEq(flow.balance(p1,ASSET_PIS),100000000);//6

        ///test vote
        p1.callDeposit(voteManager,40000000,ASSET_PIS);
        tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
        assertTrue(!tempBool);//7
        tempBool = p1.callTempConfig(paiDAO,"Vote",voteManager,0);
        assertTrue(tempBool);//8
        tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
        assertTrue(!tempBool);//9
        tempBool = p1.callTempConfig(paiDAO,"VOTE",voteManager,0);
        assertTrue(tempBool);//10
        tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE1",4,paiDAO,hex"e51ed97d",hex"",10000000);
        assertTrue(tempBool);//11
        tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE2",3,paiDAO,hex"e51ed97d",hex"",20000000);
        assertTrue(tempBool);//12
        tempBool = p1.callStartVoteTo(voteManager,voteContract,"TESTVOTE3",2,paiDAO,hex"e51ed97d",hex"",30000000);
        assertTrue(tempBool);//13
        uint mostVote;
        (mostVote,) = voteManager.getMostVote(p1);
        assertEq(mostVote,30000000);//14
        uint t1 = voteContract.timeNow();
        assertEq(t1,0);//15
        voteContract.fly(2);
        assertEq(voteContract.timeNow(),0);//16

        // (mostVote,) = voteManager.getMostVote(p1);
        // assertEq(mostVote,30000000);//15
        // voteContract.fly(3);
        // (mostVote,) = voteManager.getMostVote(p1);
        // assertEq(mostVote,30000000);//16
        // voteContract.fly(4);
        // (mostVote,) = voteManager.getMostVote(p1);
        // assertEq(mostVote,30000000);//17


    }
}