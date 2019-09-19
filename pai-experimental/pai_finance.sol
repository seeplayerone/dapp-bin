pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";

contract Finance is Template,ACLSlave,DSMath {
    PAIIssuer public issuer;
    address tdc;
    uint96 public ASSET_PAI;
    uint public operationCashLimit;

    constructor(address paiMainContract, address _issuer,address _tdc) public {
        master = ACLMaster(paiMainContract);
        issuer = PAIIssuer(_issuer);
        tdc = _tdc;
        ASSET_PAI = issuer.PAIGlobalId();
    }

    function() public payable {}

    function payForInterest(uint amount, address receiver) public auth("TDCContract") {
        receiver.transfer(amount,ASSET_PAI);
    }

    function payForDebt(uint amount) public auth("LiqudatorContract") {
        if (0 == amount)
            return;
        if (flow.balance(this,ASSET_PAI) > amount) {
            msg.sender.transfer(amount,ASSET_PAI);
        } else {
            msg.sender.transfer(flow.balance(this,ASSET_PAI),ASSET_PAI);
        }
    }

    function payForDividends(uint amount) public auth("DividendsContract") {
        require(amount > 0);
        msg.sender.transfer(amount,ASSET_PAI);
    }

    function operationCashOut(uint amount, address dest) public auth("CFO") {
        require(amount > 0);
        require(operationCashLimit >= amount);
        operationCashLimit = sub(operationCashLimit,amount);
        dest.transfer(amount,ASSET_PAI);
    }

    function increaseOperationCashLimit(uint amount) public auth("PISVOTE") {
        
    }
}