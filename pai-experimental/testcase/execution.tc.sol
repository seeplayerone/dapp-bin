pragma solidity 0.4.25;
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract EXEC is Template, Execution {
    function() public payable {}

    function exec1(address addr, bytes param) public {
        execute(addr,param);
    }

    function exec2(address addr, bytes param, uint amount, uint96 assetType) public {
        executeWithAsset(addr,param,amount,assetType);
    }
}

contract Business is Template {
    uint public state = 0;
    uint96 ASSET_PAI;
    function plusOne() public {
        state = state + 1;
    }

    function plusTen() public payable {
        require(msg.assettype == ASSET_PAI);
        require(msg.value == 1000);
        state = state + 10;
    }

    function plus(uint num) public {
        state = state + num;
    }

    function plus2(uint num1,uint num2) public {
        state = state + num1 + num2;
    }

    function plus3(uint num1,uint num2) public payable {
        require(msg.assettype == ASSET_PAI);
        require(msg.value == 2000);
        state = state + num1 + num2;
    }

    function setAssetType(uint96 _type) public {
        ASSET_PAI = _type;
    }

}

contract EXECTest is Template,DSTest {
    uint96 ASSET_PAI;
    function testMain() public {
        FakePAIIssuer issur = new FakePAIIssuer();
        issur.init("ab");
        ASSET_PAI = uint96(issur.getAssetType());

        Business business = new Business();
        business.setAssetType(uint96(issur.getAssetType()));

        EXEC exec = new EXEC();

        issur.mint(1000000, exec);

        assertEq(business.state(),0);
        //plusOne()
        exec.exec1(business,hex"68e5c066");
        assertEq(business.state(),1);
        //plusTen()
        uint emm = flow.balance(exec,ASSET_PAI);
        exec.exec2(business,hex"40993a3c",1000,ASSET_PAI);
        assertEq(business.state(),11);
        assertEq(emm - flow.balance(exec,ASSET_PAI),1000);
        //plus(uint num) num = 3
        exec.exec1(business,hex"952700800000000000000000000000000000000000000000000000000000000000000003");
        assertEq(business.state(),14);
        //plus2(uint num1,uint num2) num1 = 5; num2 = 6;
        exec.exec1(business,hex"de90eafc00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000006");
        assertEq(business.state(),25);
        //plus3(uint num1,uint num2) num1 = 7; num2 = 8;
        emm = flow.balance(exec,ASSET_PAI);
        exec.exec2(business,hex"28768f9600000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000008",2000,ASSET_PAI);
        assertEq(business.state(),40);
        assertEq(emm - flow.balance(exec,ASSET_PAI),2000);
    }

    function testFail() public {
        //not enough money
        FakePAIIssuer issur = new FakePAIIssuer();
        issur.init("ab");
        ASSET_PAI = uint96(issur.getAssetType());

        Business business = new Business();
        business.setAssetType(uint96(issur.getAssetType()));

        EXEC exec = new EXEC();
        exec.exec2(business,hex"40993a3c",1000,ASSET_PAI);
    }

    function testFailCompare() public {
        FakePAIIssuer issur = new FakePAIIssuer();
        issur.init("ab");
        ASSET_PAI = uint96(issur.getAssetType());

        Business business = new Business();
        business.setAssetType(uint96(issur.getAssetType()));

        EXEC exec = new EXEC();
        issur.mint(1000000, exec);
        exec.exec2(business,hex"40993a3c",1000,ASSET_PAI);
    }

    function testFail2() public {
        //not right money
        FakePAIIssuer issur = new FakePAIIssuer();
        issur.init("ab");
        ASSET_PAI = uint96(issur.getAssetType());

        Business business = new Business();
        business.setAssetType(uint96(issur.getAssetType()));

        EXEC exec = new EXEC();
        issur.mint(1000000, exec);
        exec.exec2(business,hex"40993a3c",200,ASSET_PAI);
    }
}