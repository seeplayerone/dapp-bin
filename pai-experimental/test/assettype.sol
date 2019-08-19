pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";

contract AssetType is Template {

    event Type(uint);

    function test() public payable {
        emit Type(msg.assettype);
    }
    
}