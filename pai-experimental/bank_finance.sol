pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";

contract Finance is Template,ACLSlave,DSMath {
    constructor(address paiMainContract) public {
        master = ACLMaster(paiMainContract);
    }

    function() public payable {
    }

    function cashOut(uint96 assetGlobalId, uint amount, address dest) public auth("Director@Bank") {
        require(amount > 0);
        dest.transfer(amount,assetGlobalId);
    }
}