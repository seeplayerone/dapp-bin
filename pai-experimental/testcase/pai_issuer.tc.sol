pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

import "./fakeperson.sol";

contract FakePAIIssuer is PAIIssuer {
    constructor(string _organizationName, address paiMainContract)
        PAIIssuer(_organizationName,paiMainContract)
    public {
        templateName = "Fake-Template-Name-For-Test-pai_issuer";
    }
}

contract FakePaiDao is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-pai_main";
    }
}

contract FakePaiDaoNoGovernance is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-pai_main2";
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        return true;
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        return true;
    }
}

contract TestCase is Template, DSTest {
    uint96 ASSET_PIS;
    uint96 ASSET_PAI;
    function() public payable {}

    function testInit() public {
        FakePaiDaoNoGovernance paiDAO = new FakePaiDaoNoGovernance("PAIDAO");
        paiDAO.init();
        FakePAIIssuer issuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        issuer.init();

        FakePerson p1 = new FakePerson();

        ASSET_PIS = paiDAO.PISGlobalId();
        ASSET_PAI = issuer.PAIGlobalId();

        paiDAO.mint(100000000,p1);
        assertEq(100000000,flow.balance(p1,ASSET_PIS));//0

        issuer.mint(200000000,p1);
        assertEq(200000000,flow.balance(p1,ASSET_PAI));//1
    }

    function testAssetRelated() public {
        FakePaiDaoNoGovernance paiDAO = new FakePaiDaoNoGovernance("PAIDAO");
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        FakePAIIssuer issuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        issuer.init();
        ASSET_PAI = issuer.PAIGlobalId();

        FakePerson p1 = new FakePerson();
        p1.callMint(issuer,100000000,p1);
        (bool exist, string memory name, string memory symbol, string memory description, uint32 assetType, uint totalSupply) =
            issuer.getAssetInfo(0);
        assertTrue(exist);//0
        assertEq(name,"PAI");//1
        assertEq(symbol,"PAI");//2
        assertEq(description,"PAI Stable Coin");//3
        assertEq(uint(assetType),0);//4
        assertEq(totalSupply,100000000);//5

        issuer.mint(100000000,p1);
        (,,,,,totalSupply) = issuer.getAssetInfo(0);
        assertEq(totalSupply,200000000);//6
        bool tempBool = p1.callBurn(issuer,50000000,ASSET_PAI);
        assertTrue(tempBool);//7
        (,,,,,totalSupply) = issuer.getAssetInfo(0);
        assertEq(totalSupply,150000000);//8
    }

    function testGovernance() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();
        FakePerson p2 = new FakePerson();
        // FakePerson p4 = new FakePerson();
        // FakePerson p5 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        FakePAIIssuer issuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        issuer.init();
        ASSET_PAI = issuer.PAIGlobalId();

        bool tempBool = p1.callMint(issuer,100000000,p1);
        assertTrue(tempBool);
        tempBool = p2.callMint(issuer,100000000,p1);
        assertTrue(!tempBool);



    }
}