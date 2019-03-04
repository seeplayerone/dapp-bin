pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/string_utils.sol";

interface TemplateWarehouse{
    function getTemplate(uint16 _category, string name) external returns(string, bytes, uint, uint8, uint8, uint8, uint16);
}

/// @title This is the base contract any other contracts must directly or indirectly inherit to run on Flow platform
///  Flow only accepts a template rather than a randomly composed Solidity contract
///  A Flow template always belongs to a given category and has a unique template name in the category
contract Template {
    uint16 category;
    string templateName;
    TemplateWarehouse templateWarehouse;
    
    event RecordAddress(
       address addr
    );
    
    constructor() public {
        templateWarehouse = TemplateWarehouse(0xb11Daac2A8f3f9B8CfAF8be885b583212477e004);
    }
    
    /// @dev initialize a template
    ///  it was originally the logic inside the constructor
    ///  it is changed in such way to provide a better user experience in the Flow debugging tool
    function initTemplate(uint16 _category, string _templateName) public {
        require(msg.sender == 0xf1512CCD48Bf5b352f2b44482afB37E22aAD3892);
        category = _category;
        templateName = _templateName;
    }

    /// @dev TEST ONLY: MUST BE REMOVED AFTER THE TEST IS DONE
    function initTemplateExternal(uint16 _category, string _templateName) public {
        category = _category;
        templateName = _templateName;
    }
    
    /// @dev get the template information
    function getTemplateInfo() public view returns (uint16, string){
        return (category, templateName);
    }
    
    /// @dev deploy contract 
    function deployContract(uint16 _category, string _templateName, bytes _constructorParam) public returns (address) {
        bytes memory byteCode;
        uint16 status;
        
        (,byteCode,,,,,status) = templateWarehouse2.getTemplate(_category, _templateName);
        // make sure template is approved
        require(status == 1);
        
        // calculate input
        bytes memory input;
         if (_constructorParam.length > 0) {
            input = mergeBytes(byteCode, _constructorParam);
        } else {
            input = byteCode;
        }
        
        address deployedAddress;
        assembly {
          deployedAddress := create(0, add(input, 0x20), mload(input))
        }
        
        require(deployedAddress != 0x0000000000000000000000000000000000000000000000000000000000000000);
        Template t = Template(deployedAddress);
        t.initTemplateExternal(_category, _templateName);
        emit RecordAddress(deployedAddress);
        return deployedAddress; 
    }  

}
