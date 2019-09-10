pragma solidity 0.4.25;

// import "../library/template.sol";
// import "./3rd/math.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";

contract PriceOracle is Template, ACLSlave, DSMath {
    /// asset prices against PAI
    /// price should be set in RAY
    bool private settlement;

    uint public lastUpdateBlock; // in blockheights
    uint public lastUpdatePrice; // in RAY
    uint public updateInterval;  // in blockheights
    uint public sensitivityTime; // must be multiple of updateInterval,  in blockheights
    uint public sensitivityRate; // in RAY

    uint[128] private priceHistory;
    uint8 private lastUpdateIndex;
    string public ORACLE;

    struct singlePirce {
        address updater;
        uint price;
    }
    singlePirce[] pirces;

    constructor(string orcaleGroupName, address paiMainContract, uint _price) public {
        ORACLE = orcaleGroupName;
        master = ACLMaster(paiMainContract);
        lastUpdateBlock = height();
        lastUpdatePrice = _price;
        lastUpdateIndex = 0;
        priceHistory[0] = lastUpdatePrice;
        updateInterval = 6;
        sensitivityTime = 120;
        sensitivityRate = RAY / 5;
    }

    function updatePrice(uint256 newPrice) public auth(ORACLE) {
        require(!settlement);
        require(newPrice > 0);
        updatePriceInternal(newPrice);
        if (sub(height(),lastUpdateBlock) <= updateInterval && master.getMemberLimit(bytes(ORACLE)) / 2 < pirces.length) {
            lastUpdateBlock = add(lastUpdateBlock, mul(sub(height(),lastUpdateBlock) / updateInterval, updateInterval));
            lastUpdateIndex = lastUpdateIndex + uint8 (sub(height(),lastUpdateBlock) / updateInterval); //overflow is expected;
            uint priceCalculated = calculatePrice();
            uint priceCompared = comparedPrice();
            if (rmul(priceCalculated,add(RAY,sensitivityRate)) > priceCompared) {
                lastUpdatePrice = rmul(priceCalculated,add(RAY,sensitivityRate));
            } else if (rmul(priceCalculated,sub(RAY,sensitivityRate)) < priceCompared) {
                lastUpdatePrice = rmul(priceCalculated,sub(RAY,sensitivityRate));
            } else {
                lastUpdatePrice = priceCalculated;
            }
            priceHistory[lastUpdateIndex] = lastUpdatePrice;
            pirces.length = 0;
        }
    }

    function updatePriceInternal(uint newPrice) internal {
        uint len = pirces.length;
        for(uint i; i < len; i++) {
            if(msg.sender == pirces[i].updater) {
                pirces[i].price = newPrice;
                return;
            }
        }
        pirces[len].updater = msg.sender;
        pirces[len].price = newPrice;
    }

    function comparedPrice() internal view returns(uint) {
        uint8 index = lastUpdateIndex - uint8(sensitivityTime / updateInterval);  //overflow is expected;
        for(uint8 i = 0; i < 3; i++) {
            if(priceHistory[index + i] > 0) {
                return priceHistory[index + i];
            }
        }
        return lastUpdatePrice;
    }

    function calculatePrice() internal view returns (uint) {
        require(pirces.length > 2);
        uint sum;
        uint maxPrice;
        uint minPrice;
        uint len = pirces.length;
        for(uint i; i < len; i++) {
            if(pirces[i].price > maxPrice) {
                maxPrice = pirces[i].price;
            }
            if(pirces[i].price < minPrice || 0 == minPrice) {
                minPrice = pirces[i].price;
            }
            sum = add(sum,pirces[i].price);
        }
        return sub(sum,add(maxPrice,minPrice)) / (len - 2);
    }

    function getPrice() public view returns (uint256) {
        return lastUpdatePrice;
    }

    function height() public view returns (uint) {
        return block.number;
    }

    /// terminate the business and provide a final collateral price
    /// note this `price` is used for liquidation CDPs in settlement process
    /// the final price used to redeem PAI for collateral in the liquidator is calculated later by the liquidator itself
    function terminate() public auth("SettlementContract") {
        require(!settlement);
        settlement = true;
    }
}