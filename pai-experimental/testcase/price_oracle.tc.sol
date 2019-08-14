pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../price_oracle.sol";
// import "../3rd/test.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

contract PriceOracleTest is Template, DSTest {
    PriceOracle private oracle;

    function setup() public {
        oracle = new PriceOracle();        
    }

    function testUpdatePriceSuccess() public {
        setup();
        oracle.updatePrice(0, 88);
        assertEq(88, oracle.getPrice(0));
    }

    function testUpdatePriceFail() public {
        setup();
        oracle.updatePrice(0, 88);
        assertEq(77, oracle.getPrice(0));
    }
}