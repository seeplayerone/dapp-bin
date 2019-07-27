pragma solidity 0.4.25;

//import "../template.sol";
//import "./math.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/3rd/math.sol";

contract PriceOracle is Template {
    /// asset prices against PAI
    /// asset => price 
    /// TODO should be calculated in RAY or WAD?
    mapping (uint256 => uint256) private prices;

    function getPrice(uint256 asset) public view returns (uint256) {
        return prices[asset];
    }

    function updatePrice(uint256 asset, uint256 price) public {
        /// TODO only accept calls from authorized addresses
        prices[asset] = price;
    }
}