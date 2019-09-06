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
        execute(addr,param,amount,assetType);
    }
}

contract Business is Template {
    uint public states = 0;
    uint96 ASSET_PAI;
    function plusOne() public {
        states = states + 1;
    }

    function plusTen() public payable {
        require(msg.assetType == ASSET_PAI);
        require(msg.value == 1000);
        states = states + 10;
    }

    function plus(uint num) public {
        states = states + num;
    }

    function setAssetType(uint96 type) public {
        ASSET_PAI = type;
    }

}

contract EXECTest is Template,DSTest {
    uint96 ASSET_PAI;
    function run() public {
        FakePAIIssuer issur = new FakePAIIssuer();
        issur.init("ab");
        ASSET_PAI = uint96(issur.getAssetType());

        Business business = new Business();
        business.setAssetType(uint96(issur.getAssetType()));

        EXEC exec = new EXEC();

        issur.mint(1000000, exec);


    }

}