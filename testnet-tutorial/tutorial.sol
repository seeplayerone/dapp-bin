pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";

/// @dev Registry is a system contract on asimov chain, a contract needs to register before issuing assets
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
}

/**
    @dev this is a tutorial contract to show how to develop on asimov assets 
 */
contract Tutorial is Template {
    address hole = 0x660000000000000000000000000000000000000000;
    address registry = 0x630000000000000000000000000000000000000065;

    bool private registered = false;

    uint private index = 1;
    uint private orgnizationID = 0;
    uint private assettype;

    uint private totalSupply = 0;

    function mint(uint amount) public returns (uint){
        if(registered) {
            flow.mintAsset(index, amount);
        } else {
            Registry reg = Registry(registry);
            orgnizationID = reg.registerOrganization("Tutorial", templateName);

            registered = true;

            uint64 temp1 = uint64(assetType) << 32 | uint64(orgnizationID);
            uint96 temp2 = uint96(temp1) << 32 | uint96(assetIndex);

            assettype = temp2;

            flow.createAsset(0, index, amount);
        }
        
        return assettype;
    }

    function transfer(address to, uint amount) public {
        to.transfer(amount, assettype);
    }

    function burn() public payable {
        hole.transfer(msg.value, msg.assettype);
        totalSupply = totalSupply - msg.value;
    }

    function checkBalance() public view returns (uint) {
        return flow.balance(this, assettype);
    }

    function checkTotalSupply() public view returns (uint) {
        return totalSupply;
    }
}

