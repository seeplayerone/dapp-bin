pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";

contract PriceOracle is Template, ACLSlave, DSMath {
    /// asset prices against PAI
    /// price should be set in RAY
    bool private settlement;
    uint96 public assetId;
    uint public lastUpdateBlock; // in blockheights
    uint public lastUpdatePrice; // in RAY
    uint public updateInterval;  // in blockheights
    uint public sensitivityTime; // should be multiple of updateInterval,  in blockheights
    uint public sensitivityRate; // in RAY
    uint public priceUpperLimit = 1 << 200;
    uint8 public effectivePriceNumber;

    uint[256] private priceHistory;
    uint8 private lastUpdateIndex;
    uint8 public disableOracleLimit;
    string public ORACLE;
    address[] public disabledOracle;

    struct SinglePirce {
        address updater;
        uint price;
    }
    SinglePirce[] prices;

    /// @dev 相关参数都应该可以通过构造函数设置而不是写死了
    constructor(string oracleGroupName, address pisContract, uint _price, uint96 _assetId) public {
        ORACLE = oracleGroupName;
        master = ACLMaster(pisContract);
        lastUpdateBlock = block.number;
        lastUpdatePrice = _price;
        lastUpdateIndex = 0;
        priceHistory[0] = lastUpdatePrice;
        updateInterval = 6;
        sensitivityTime = 60;
        sensitivityRate = RAY / 20;
        disableOracleLimit = 5;
        assetId = _assetId;
        effectivePriceNumber = 4;
    }

    function updatePrice(uint256 newPrice) public auth(ORACLE) {
        require(!settlement);
        require(newPrice > 0);
        require(newPrice < priceUpperLimit);
        require(!disabled(msg.sender));
        updateSinglePriceInternal(newPrice);
        if(sub(height(),lastUpdateBlock) >= updateInterval) {
            updateOverallPrice();
        }
    }

    function updateSinglePriceInternal(uint newPrice) internal {
        uint len = prices.length;
        for(uint i; i < len; i++) {
            if(msg.sender == prices[i].updater) {
                prices[i].price = newPrice;
                return;
            }
        }
        SinglePirce memory temp;
        temp.updater = msg.sender;
        temp.price = newPrice;
        prices.push(temp);
    }

    function updateOverallPrice() internal {
        if (effectivePriceNumber > prices.length) {
            lastUpdateBlock = height();
            lastUpdateIndex = uint8(lastUpdateIndex + 1); //overflow is expected;
            //the lastUpdatePrice also needs to be updated, but its value needs no change, so the following code is noted.
            //lastUpdatePrice = lastUpdatePrice;
            priceHistory[lastUpdateIndex] = lastUpdatePrice;
            return;
        }
        lastUpdateBlock = height();
        lastUpdateIndex = uint8(lastUpdateIndex + 1); //overflow is expected;
        uint priceCalculated = calculatePrice();
        uint priceCompared1 = rmul(comparedPrice(),add(RAY,sensitivityRate));
        uint priceCompared2 = rmul(comparedPrice(),sub(RAY,sensitivityRate));
        if (priceCalculated > priceCompared1) {
            lastUpdatePrice = priceCompared1;
        } else if (priceCalculated < priceCompared2) {
            lastUpdatePrice = priceCompared2;
        } else {
            lastUpdatePrice = priceCalculated;
        }
        priceHistory[lastUpdateIndex] = lastUpdatePrice;
        prices.length = 0;
    }

    function comparedPrice() internal view returns(uint) {
        uint8 index = uint8(lastUpdateIndex - uint8(sensitivityTime / updateInterval));  //overflow is expected;
        if(priceHistory[index] > 0) {
            return priceHistory[index];
        }
        return lastUpdatePrice;
    }

    function calculatePrice() internal view returns (uint) {
        require(prices.length > 2);
        uint sum;
        uint maxPrice;
        uint minPrice = uint(-1);
        uint len = prices.length;
        for(uint i; i < len; i++) {
            if(prices[i].price > maxPrice) {
                maxPrice = prices[i].price;
            }
            if(prices[i].price < minPrice) {
                minPrice = prices[i].price;
            }
            sum = add(sum,prices[i].price);
        }
        return sub(sum,add(maxPrice,minPrice)) / (len - 2);
    }

    function modifyEffectivePriceNumber(uint8 number) public auth("DirVote@STCoin") {
        require(number >= 3);
        effectivePriceNumber = number;
    }

    function modifyUpdateInterval(uint newInterval) public auth("DirVote@STCoin") {
        require(newInterval > 0);
        updateInterval = newInterval;
    }

    function modifySensitivityTime(uint newTime) public auth("DirVote@STCoin") {
        require(newTime > updateInterval);
        sensitivityTime = newTime;
    }

    function modifySensitivityRate(uint newRate) public auth("DirVote@STCoin") {
        require(newRate > RAY / 10000);
        sensitivityRate = newRate;
    }

    function modifyDisableOracleLimit(uint8 newlimit) public auth("DirVote@STCoin") {
        disableOracleLimit = newlimit;
    }

    function emptyDisabledOracle() public auth("DirVote@STCoin") {
        disabledOracle.length = 0;
    }
    
    function disableOne(address addr) public auth("OracleManager@STCoin") {
        require(disableOracleLimit > disabledOracle.length);
        for(uint i = 0; i < disabledOracle.length; i++) {
            if (addr == disabledOracle[i]) {
                return;
            }
        }
        disabledOracle.push(addr);
    }

    function enableOne(address addr) public auth("OracleManager@STCoin") {
        uint len = disabledOracle.length;
        for(uint i = 0; i < len; i++) {
            if (addr == disabledOracle[i]) {
                if(i != len - 1) {
                    disabledOracle[i] = disabledOracle[len - 1];
                }
                disabledOracle.length--;
                return;
            }
        }
    }

    function disabledNumber() public view returns (uint) {
        return disabledOracle.length;
    }

    function disabled(address addr) public view returns (bool) {
        for(uint i = 0; i < disabledOracle.length; i++) {
            if (addr == disabledOracle[i]) {
                return true;
            }
        }
        return false;
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
    function terminate() public auth("Settlement@STCoin") {
        require(!settlement);
        settlement = true;
    }
}