pragma solidity 0.4.25;

import "../library/template.sol";
import "../pai-experimental/fake_btc_issuer.sol";

contract AcceptMoney {
    uint public money;

    function updateMoney() public payable {
        money = msg.value;
        msg.sender.transfer(msg.value,msg.assettype);
    }
}


contract TestBase is Template {
    uint ASSET_BTC;
    event showNumber(uint num);

    function() public payable {}

    function testMoney() public {
        FakeBTCIssuer btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("sb2");
        ASSET_BTC = btcIssuer.getAssetType();
        btcIssuer.mint(1000000000000, this);


        address am = new AcceptMoney();

        bytes4 methodId = bytes4(keccak256("updateMoney()"));
        
        am.call.value(10000, ASSET_BTC)(abi.encodeWithSignature("updateMoney()")); // works
        emit showNumber(AcceptMoney(am).money());

        am.call.value(20000, ASSET_BTC)(abi.encodeWithSelector(methodId)); // works
        emit showNumber(AcceptMoney(am).money());

        am.call.value(30000, ASSET_BTC)(methodId); // not working
        emit showNumber(AcceptMoney(am).money());
    }
}