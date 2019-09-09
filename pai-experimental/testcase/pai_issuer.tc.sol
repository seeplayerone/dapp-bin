pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

contract FakePerson is Template {
    function() public payable {}

    // function createPAIDAO(string _str) public returns (address) {
    //     return (new FakePaiDao(_str));
    // }
}

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

    // function testCreate() public {
    //     setup();
    //     issuer.mint(100000000, dest);
    //     assertEq(100000000, flow.balance(dest, issuer.getAssetType()));
    // }

    // function testCreateAndMint() public {
    //     setup();
    //     issuer.mint(100000000, dest);
    //     issuer.mint(100000000, dest);
    //     assertEq(200000000, flow.balance(dest,issuer.getAssetType()));
    // }
    
    // function testCreateBurn() public {
    //     setup();
    //     issuer.mint(200000000, this);

    //     assertEq(200000000, flow.balance(this, issuer.getAssetType()));
    //     issuer.burn.value(100000000, issuer.getAssetType())();

    //     assertEq(100000000, flow.balance(this, issuer.getAssetType()));
    //     assertEq(100000000, flow.balance(hole, issuer.getAssetType()));
    // }
}