pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";

contract PriceOracle is Template, ACLSlave, DSMath {
    /// asset prices against PAI
    /// price should be set in RAY
    bool private settlement;
    uint96 public ASSET_COLLATERAL;
    uint public lastUpdateBlock; // in blockheights
    uint public lastUpdatePrice; // in RAY
    uint public updateInterval;  // in blockheights
    uint public sensitivityTime; // should be multiple of updateInterval,  in blockheights
    uint public sensitivityRate; // in RAY

    uint[256] private priceHistory;
    uint8 private lastUpdateIndex;
    uint8 public disableOracleLimit;
    string public ORACLE;
    address[] public disabledOracle;

    struct singlePirce {
        address updater;
        uint price;
    }
    singlePirce[] pirces;

    constructor(string orcaleGroupName, address paiMainContract, uint _price, uint96 CollateralId) public {
        ORACLE = orcaleGroupName;
        master = ACLMaster(paiMainContract);
        lastUpdateBlock = block.number;
        lastUpdatePrice = _price;
        lastUpdateIndex = 0;
        priceHistory[0] = lastUpdatePrice;
        updateInterval = 6;
        sensitivityTime = 60;
        sensitivityRate = RAY / 20;
        disableOracleLimit = 5;
        ASSET_COLLATERAL = CollateralId;
    }

    function updatePrice(uint256 newPrice) public auth(ORACLE) {
        require(!settlement);
        require(newPrice > 0);
        /// @notice 每次都做位移运算会不会浪费gas，是不是直接算出来记录一个常量更好
        require(newPrice < (1 << 200));
        require(!disabled(msg.sender));
        updateSinglePriceInternal(newPrice);
        if(sub(height(),lastUpdateBlock) >= updateInterval) {
            updateOverallPrice();
        }
    }

    function updateSinglePriceInternal(uint newPrice) internal {
        uint len = pirces.length;
        for(uint i; i < len; i++) {
            if(msg.sender == pirces[i].updater) {
                pirces[i].price = newPrice;
                return;
            }
        }
        singlePirce memory temp;
        temp.updater = msg.sender;
        temp.price = newPrice;
        pirces.push(temp);
    }

    function updateOverallPrice() internal {
        if (master.getMemberLimit(bytes(ORACLE)) / 2 >= pirces.length) {
            lastUpdateBlock = height();
            /// @notice 需要确保这个uint8能够被循环利用 256->0
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
        pirces.length = 0;
    }

    function comparedPrice() internal view returns(uint) {
        uint8 index = uint8(lastUpdateIndex - uint8(sensitivityTime / updateInterval));  //overflow is expected;
        if(priceHistory[index] > 0) {
            return priceHistory[index];
        }
        return lastUpdatePrice;
    }

    function calculatePrice() internal view returns (uint) {
        require(pirces.length > 2);
        uint sum;
        uint maxPrice;
        uint minPrice = uint(-1);
        uint len = pirces.length;
        for(uint i; i < len; i++) {
            if(pirces[i].price > maxPrice) {
                maxPrice = pirces[i].price;
            }
            if(pirces[i].price < minPrice) {
                minPrice = pirces[i].price;
            }
            sum = add(sum,pirces[i].price);
        }
        return sub(sum,add(maxPrice,minPrice)) / (len - 2);
    }

    function modifyUpdateInterval(uint newInterval) public auth("DIRECTORVOTE") {
        require(newInterval > 0);
        updateInterval = newInterval;
    }

    function modifySensitivityTime(uint newTime) public auth("DIRECTORVOTE") {
        require(newTime > updateInterval);
        sensitivityTime = newTime;
    }

    function modifySensitivityRate(uint newRate) public auth("DIRECTORVOTE") {
        require(newRate > RAY /10000);
        sensitivityRate = newRate;
    }

    function modifyDisableOracleLimit(uint8 newlimit) public auth("DIRECTORVOTE") {
        disableOracleLimit = newlimit;
    }

    function emptyDisabledOracle() public auth("DIRECTORVOTE") {
        disabledOracle.length = 0;
    }
    
    function disableOne(address addr) public auth("ORACLEMANAGER") {
        require(disableOracleLimit > disabledOracle.length);
        for(uint i = 0; i < disabledOracle.length; i++) {
            if (addr == disabledOracle[i]) {
                return;
            }
        }
        disabledOracle.push(addr);
    }

    function enableOne(address addr) public auth("ORACLEMANAGER") {
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

    /// @notice 不应该允许换资产类型，可能会造成逻辑变的非常复杂，建议直接采取部署新合约的方式。
    function updateCollateral(uint96 newId) public auth("DIRECTORVOTE") {
        ASSET_COLLATERAL = newId;
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