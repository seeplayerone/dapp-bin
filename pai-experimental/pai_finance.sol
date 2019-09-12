pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";

contract Finance is Template {
    PAIIssuer public issuer;
    uint private ASSET_PAI;

    constructor(address _issuer) public {
        issuer = PAIIssuer(_issuer);
        ASSET_PAI = issuer.PAIGlobalId();
    }

    function() public payable {}

    function payForInterest(uint amount, address receiver) public {
        receiver.transfer(amount,ASSET_PAI);
    }
}