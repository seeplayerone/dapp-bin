pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";

contract Setting is Template, DSMath, ACLSlave {
    uint public lendingInterestRate; // in RAY
    uint public depositInterestRate; // in RAY
    uint public currentDepositFloatUp; // in RAY
    mapping(uint96 => uint) public mintPaiRatioLimit; //in RAY
    bool public globalOpen;
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
        globalOpen = true;
        lendingInterestRate = RAY / 5;
        depositInterestRate = RAY * 19 / 100;
        currentDepositFloatUp = RAY * 1 / 100;
    }

    function updateLendingRate(uint newRate) public auth("DIRECTORVOTE") {
        lendingInterestRate = newRate;
    }

    function updateDepositRate(uint newRate) public auth("DIRECTORVOTE") {
        depositInterestRate = newRate;
    }

    function updateCurrentDepositFloatUp(uint newRate) public auth("DIRECTORVOTE") {
        currentDepositFloatUp = newRate;
    }

    function updateRatioLimit(uint96 assetGlobalId, uint ratio) public auth("DIRECTORVOTE") {
        mintPaiRatioLimit[assetGlobalId] = ratio;
    }

    function globalShutDown() public auth("DIRECTORVOTE") {
        globalOpen = false;
    }

    function globalReopen() public auth("DIRECTORVOTE") {
        globalOpen = true;
    }
}