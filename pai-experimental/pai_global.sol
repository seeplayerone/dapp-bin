pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";


contract PAIIssuer is Template, DSMath, ACLSlave {
    uint public lendingInterestRate; // in RAY
    uint public depositInterestRate; // in RAY
    mapping(uint96 => uint) public mintPaiRatioLimit; //in RAY
    bool public globalOpen;
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
        globalOpen = true;
    }

    function updateLendingRate(uint newRate) public auth("DIRECTORVOTE") {
        require(newRate > 0);
        lendingInterestRate = newRate;
    }

    function updateDepositRate(uint newRate) public auth("DIRECTORVOTE") {
        require(newRate > 0);
        depositInterestRate = newRate;
    }

    function setRatioLimit(uint96 assetGlobalId, uint ratio) public auth("DIRECTORVOTE") {
        mintPaiRatioLimit[assetGlobalId] = ratio;
    }

    function globalShutDown() public auth("DIRECTORVOTE") {
        globalOpen = false;
    }

    function globalReopen() public auth("DIRECTORVOTE") {
        globalOpen = true;
    }
}