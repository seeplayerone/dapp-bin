pragma solidity 0.4.25;

// import "../library/template.sol";
// import "./3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";

contract PriceOracle is Template {
    /// asset prices against PAI
    /// asset => price 
    /// price should be set in RAY
    bool private settlement;
    mapping (uint256 => uint256) private prices;

    function getPrice(uint256 asset) public view returns (uint256) {
        return prices[asset];
    }

    function updatePrice(uint256 asset, uint256 price) public {
        /// TODO only accept calls from authorized addresses
        require(!settlement);
        prices[asset] = price;
    }

    function terminate(uint256 asset, uint256 finalPrice) public {
        require(!settlement);
        prices[asset] = finalPrice;
        settlement = true;
    }

    ///only for debug
    function reopen() public {
        settlement = false;
    }

    function checkState() public view returns (bool) {
        return settlement;
    }
}