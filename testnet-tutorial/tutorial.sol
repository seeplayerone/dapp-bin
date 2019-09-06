pragma solidity 0.4.25;

/**
    @dev a contract needs to inherit TEMPLATE directly or indirectly to run on asimov chain
     the standard precedure to develop/run a contract on asimov goes as:
     1. write a smart contract in SOLIDITY version 0.4.25
     2. create a TEMPLATE on asimov based on the above source code (using IDE tool)
     3. deploy a contract INSTANCE based on the TEMPLATE (using IDE tool)
     4. call contract function by returned address

    @dev before creating a TEMPLATE on asimov for business usage
     we recommend to write full testcases and have them passed (using IDE tool)
 */

import "github.com/seeplayerone/dapp-bin/library/template.sol";

/**
    @dev Registry is a system contract on asimov chain, a contract needs to register before issuing assets
 */ 
interface Registry {
     function registerOrganization(string organizationName, string templateName) external returns(uint32);
}

/**
    @dev this tutorial demostrates the EXCLUSIVE asset instructions of asimov
     1. register an organization to asimov blockchain
     2. create/mint UTXO assets 
     3. transfer UTXO assets
     4. check balance
 */
contract Tutorial is Template {
    /// black hole
    address hole = 0x660000000000000000000000000000000000000000;
    /// registry system contract
    address registry = 0x630000000000000000000000000000000000000065;

    bool private registered = false;

    /// asset properties
    uint private properties = 0;
    /// asset index
    uint private index = 1;
    /// organization id, assigned after registration
    uint private orgnizationID = 0;
    /// assettype of UTXO => 32bit properteis + 32 bit organization id + 32 bit asset index
    uint private assettype;

    /// total supply 
    uint private totalSupply = 0;

    /**
        @dev mint assets with given amount
     */
    function mint(uint amount) public returns (uint){
        if(registered) {
            /// @dev instruction to mint more on an existing asset
            flow.mintAsset(index, amount);
        } else {
            /// register the organization (contract) before issuing assets
            Registry reg = Registry(registry);
            /// template name is given when submitting a TEMPLATE using IDE tool
            orgnizationID = reg.registerOrganization("Tutorial", templateName);

            registered = true;

            uint64 temp1 = uint64(0) << 32 | uint64(orgnizationID);
            uint96 temp2 = uint96(temp1) << 32 | uint96(index);

            assettype = temp2;
            
            /// @dev instruction to create a new asset with given amount
            /// properties = 0 which means this is a fungible asset
            /// index = 1 which means this is the first asset created by this oraganization
            ///  an organization can create multiple assets with different indexes
            flow.createAsset(properties, index, amount);
        }
        
        totalSupply = totalSupply + amount;

        return assettype;
    }

    /**
        @dev transfer an asset using `transfer` instruction
     */
    function transfer(address to, uint amount) public {
        /// @dev instruction to transfer asset from a contract (with gas limit to 2300)
        to.transfer(amount, assettype);
    }

    /**
        @dev transfer an asset using `call.value` instruction
     */
    function callValue(address to, uint amount) public {
        /// @dev instruction to transfer asset from a contract using raw call
        to.call.value(amount, assettype)();
    }

    /**
        @dev burn issued assets by sending them to the black hole
     */
    function burn() public payable {
        hole.transfer(msg.value, msg.assettype);
        totalSupply = totalSupply - msg.value;
    }

    /**
        @dev check balance of this contract
     */
    function checkBalance() public view returns (uint) {
        /// @dev instruction to check balance of a given assettype on an address 
        return flow.balance(this, assettype);
    }

    /**
        @dev check total supply of the asset
     */
    function checkTotalSupply() public view returns (uint) {
        return totalSupply;
    }
}

