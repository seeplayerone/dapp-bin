pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../pai_issuer.sol";
// import "../3rd/test.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/pai_issuer_t.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

contract PAIIssuerTest is Template, DSTest {
    PAIIssuer private issuer;
    address private dest = 0x668eb397ce8ccc9caec9fec1b019a31f931725ca94;

    function setup() public {
        issuer = new PAIIssuer();
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

}