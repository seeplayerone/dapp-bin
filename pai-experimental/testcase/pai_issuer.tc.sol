pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../pai_issuer.sol";
// import "../3rd/test.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract PAIIssuerTest is Template, DSTest {
    FakePAIIssuer private issuer;
    address private dest = 0x668eb397ce8ccc9caec9fec1b019a31f931725ca94;
    address private hole = 0x660000000000000000000000000000000000000000;

    function() public payable {}

    function setup() public {
        issuer = new FakePAIIssuer();
        issuer.init("sb");
    }

    function testCreate() public {
        setup();
        issuer.mint(100000000, dest);
        assertEq(100000000, flow.balance(dest, issuer.getAssetType()));
    }

    function testCreateAndMint() public {
        setup();
        issuer.mint(100000000, dest);
        issuer.mint(100000000, dest);
        assertEq(200000000, flow.balance(dest,issuer.getAssetType()));
    }
    
    function testCreateBurn() public {
        setup();
        issuer.mint(200000000, this);

        assertEq(200000000, flow.balance(this, issuer.getAssetType()));
        issuer.burn.value(100000000, issuer.getAssetType())();

        assertEq(100000000, flow.balance(this, issuer.getAssetType()));
        assertEq(100000000, flow.balance(hole, issuer.getAssetType()));
    }
}