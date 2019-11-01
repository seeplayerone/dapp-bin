pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";

contract Setting is Template, DSMath, ACLSlave {
    uint public lendingInterestRate; // in RAY
    uint public depositInterestRate; // in RAY
    int public currentDepositAdjustment; // in RAY
    mapping(uint96 => uint) public paiForAssetRatioThreshold; //in RAY
    bool public globalOpen;
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
        globalOpen = true;
        lendingInterestRate = RAY / 5;
        depositInterestRate = RAY * 19 / 100;
        currentDepositAdjustment = int(RAY * 1 / 100);
    }

    function updateLendingRate(uint newRate) public auth("50%Demonstration@STCoin") {
        lendingInterestRate = newRate;
    }

    function updateDepositRate(uint newRate) public auth("50%Demonstration@STCoin") {
        depositInterestRate = newRate;
    }

    function updateCurrentDepositAdjustment(int newRate) public auth("50%Demonstration@STCoin") {
        currentDepositAdjustment = newRate;
    }

    function updateRatioLimit(uint96 assetGlobalId, uint ratio) public auth("DirVote@STCoin") {
        paiForAssetRatioThreshold[assetGlobalId] = ratio;
    }

    function globalShutDown() public auth("DirPisVote") {
        globalOpen = false;
    }

    function globalReopen() public auth("DirPisVote") {
        globalOpen = true;
    }

    function currentDepositRate() public view returns(uint) {
        if (currentDepositAdjustment > 0) {
            return add(depositInterestRate,uint(currentDepositAdjustment));
        }
        return sub(depositInterestRate,uint(-currentDepositAdjustment));
    }
}