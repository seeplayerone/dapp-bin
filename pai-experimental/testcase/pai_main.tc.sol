pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO(string _str) public returns (address) {
        return (new FakePaiDao(_str));
    }

    function createPAIDAONoGovernance(string _str) public returns (address) {
        return (new FakePaiDaoNoGovernance(_str));
    }

    function callInit(address paidao) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("init()"));
        bool result = PAIDAO(paidao).call(methodId);
        return result;
    }

    function callCreateNewRole(address paidao, string newRole, string superior) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("createNewRole(bytes,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,bytes(newRole),bytes(superior)));
        return result;
    }

    function callAddMember(address paidao, address _address, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("addMember(address,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,_address,bytes(role)));
        return result;
    }

    function callRemoveMember(address paidao, address _address, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("removeMember(address,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,_address,bytes(role)));
        return result;
    }

    function callMint(address paidao, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,amount,dest));
        return result;
    }

    function callBurn(address paidao, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("burn()"));
        bool result = PAIDAO(paidao).call.value(amount,id)(abi.encodeWithSelector(methodId));
        return result;
    }

    function callResetMembers(address paidao, address[] _members, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("resetMembers(address[],bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, _members, bytes(role)));
        return result;
    }

    function callChangeSuperior(address paidao, string role, string newSuperior) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeSuperior(bytes,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),bytes(newSuperior)));
        return result;
    }

    
}

contract FakePaiDao is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-Pai_main";
    }
}

contract FakePaiDaoNoGovernance is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-Pai_main2";
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        return true;
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        return true;
    }
}

contract TestCase is Template, DSTest, DSMath {
    function() public payable {

    }
    uint96 ASSET_PIS;
    uint96 ASSET_PAI;
    string ADMIN = "ADMIN";

    function testInit() public {
        FakePaiDaoNoGovernance paiDAO;

        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();

        paiDAO = FakePaiDaoNoGovernance(p1.createPAIDAONoGovernance("PAIDAO"));
        assertTrue(paiDAO.addressExist(bytes(ADMIN),p1)); //0

        //test whether governance function is shielded
        assertTrue(paiDAO.canPerform(ADMIN,p1)); //1
        assertTrue(paiDAO.canPerform(ADMIN,p2)); //2

        bool tempBool = p2.callInit(paiDAO);
        assertTrue(tempBool);//3
        tempBool = p2.callInit(paiDAO);
        assertTrue(!tempBool);//4
        tempBool = p1.callInit(paiDAO);
        assertTrue(!tempBool);//5

        ASSET_PIS = paiDAO.PISGlobalId();
        paiDAO.mint(100000000,p2);//6
        assertEq(100000000,flow.balance(p2,ASSET_PIS));
    }

    function testAssetRelated() public {
        FakePaiDaoNoGovernance paiDAO;
        paiDAO = new FakePaiDaoNoGovernance("PAIDAO");
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        FakePerson p1 = new FakePerson();
        p1.callMint(paiDAO,100000000,p1);
        (bool exist, string memory name, string memory symbol, string memory description, uint32 assetType, uint totalSupply) =
            paiDAO.getAssetInfo(0);
        assertTrue(exist);//0
        assertEq(name,"PIS");//1
        assertEq(symbol,"PIS");//2
        assertEq(description,"Share of PAIDAO");//3
        assertEq(uint(assetType),0);//4
        assertEq(totalSupply,100000000);//5

        paiDAO.mint(100000000,p1);
        (,,,,,totalSupply) = paiDAO.getAssetInfo(0);
        assertEq(totalSupply,200000000);//6
        bool tempBool = p1.callBurn(paiDAO,50000000,ASSET_PIS);
        assertTrue(tempBool);//7
        (,,,,,totalSupply) = paiDAO.getAssetInfo(0);
        assertEq(totalSupply,150000000);//8
    }

    function testGovernance() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        FakePerson p3 = new FakePerson();
        FakePerson p4 = new FakePerson();
        FakePerson p5 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();

        assertTrue(paiDAO.addressExist(bytes(ADMIN),p1));//0
        bool tempBool = p1.callMint(paiDAO,100000000,p1);
        assertTrue(tempBool);//1
        tempBool = p2.callMint(paiDAO,100000000,p2);
        assertTrue(!tempBool);//2
        tempBool = p1.callAddMember(paiDAO,p2,"ADMIN");
        assertTrue(tempBool);//3
        tempBool = p2.callMint(paiDAO,100000000,p2);
        assertTrue(tempBool);//4
        tempBool = p2.callRemoveMember(paiDAO,p2,"ADMIN");
        assertTrue(tempBool);//5
        tempBool = p2.callMint(paiDAO,100000000,p2);
        assertTrue(!tempBool);//6


        tempBool = p1.callCreateNewRole(paiDAO,"DIRECTOR","ADMIN");
        assertTrue(tempBool);//7
        tempBool = p1.callCreateNewRole(paiDAO,"CASHIER","DIRECTOR");
        assertTrue(tempBool);//8
        tempBool = p1.callAddMember(paiDAO,p3,"DIRECTOR");
        assertTrue(tempBool);//9
        tempBool = p1.callAddMember(paiDAO,p4,"CASHIER");
        assertTrue(!tempBool);//10
        tempBool = p3.callAddMember(paiDAO,p4,"CASHIER");
        assertTrue(tempBool);//11
        tempBool = p1.callRemoveMember(paiDAO,p3,"DIRECTOR");
        assertTrue(tempBool);//12
        tempBool = p3.callAddMember(paiDAO,p5,"CASHIER");
        assertTrue(!tempBool);//13

        tempBool = p1.callCreateNewRole(paiDAO,"DIRECTOR2","ADMIN");
        assertTrue(tempBool);//14
        tempBool = p1.callCreateNewRole(paiDAO,"CASHIER2","DIRECTOR2");
        assertTrue(tempBool);//15
        tempBool = p1.callAddMember(paiDAO,p4,"CASHIER2");
        assertTrue(!tempBool);//16
        tempBool = p1.callAddMember(paiDAO,p1,"DIRECTOR2");
        assertTrue(tempBool);//17
        tempBool = p1.callAddMember(paiDAO,p2,"DIRECTOR2");
        assertTrue(tempBool);//18
        tempBool = p1.callAddMember(paiDAO,p3,"DIRECTOR2");
        assertTrue(tempBool);//19
        tempBool = p1.callRemoveMember(paiDAO,p1,"DIRECTOR2");
        assertTrue(tempBool);//20
        tempBool = p1.callAddMember(paiDAO,p4,"CASHIER2");
        assertTrue(!tempBool);//21
        tempBool = p2.callAddMember(paiDAO,p4,"CASHIER2");
        assertTrue(tempBool);//22

        address[] list;
        list.push(p1);
        list.push(p5);
        tempBool = p1.callResetMembers(paiDAO,list,"DIRECTOR2");
        assertTrue(tempBool); //23
        tempBool = p1.callAddMember(paiDAO,p2,"CASHIER2");
        assertTrue(tempBool); //24
        tempBool = p2.callAddMember(paiDAO,p3,"CASHIER2");
        assertTrue(!tempBool);//25
        tempBool = p3.callAddMember(paiDAO,p3,"CASHIER2");
        assertTrue(!tempBool);//26
        tempBool = p4.callAddMember(paiDAO,p3,"CASHIER2");
        assertTrue(!tempBool);//27
        tempBool = p5.callAddMember(paiDAO,p3,"CASHIER2");
        assertTrue(tempBool); //28


        tempBool = p1.callCreateNewRole(paiDAO,"DIRECTOR3","ADMIN");
        assertTrue(tempBool);//29
        tempBool = p1.callCreateNewRole(paiDAO,"DIRECTOR4","ADMIN");
        assertTrue(tempBool);//30
        tempBool = p1.callCreateNewRole(paiDAO,"CASHIER3","DIRECTOR3");
        assertTrue(tempBool);//31
        tempBool = p1.callAddMember(paiDAO,p2,"DIRECTOR3");
        assertTrue(tempBool);//32
        tempBool = p1.callAddMember(paiDAO,p3,"DIRECTOR4");
        assertTrue(tempBool);//33
        tempBool = p2.callAddMember(paiDAO,p4,"CASHIER3");
        assertTrue(tempBool);//34
        tempBool = p3.callAddMember(paiDAO,p5,"CASHIER3");
        assertTrue(!tempBool);//35
        tempBool = p2.callChangeSuperior(paiDAO,"CASHIER3","DIRECTOR4");
        assertTrue(!tempBool);//36
        tempBool = p1.callChangeSuperior(paiDAO,"CASHIER3","DIRECTOR4");
        assertTrue(tempBool);//37
        tempBool = p2.callAddMember(paiDAO,p5,"CASHIER3");
        assertTrue(!tempBool);//38
        tempBool = p3.callAddMember(paiDAO,p5,"CASHIER3");
        assertTrue(tempBool);//39
    }
}