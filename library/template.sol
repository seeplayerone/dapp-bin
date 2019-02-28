pragma solidity 0.4.25;

interface TemplateWarehouse{
    function getTemplate(uint16 _category, string name) external returns(string, string, uint, uint8, uint8, uint8, uint16);
}

/// @title This is the base contract any other contracts must directly or indirectly inherit to run on Flow platform
///  Flow only accepts a template rather than a randomly composed Solidity contract
///  A Flow template always belongs to a given category and has a unique template name in the category
contract Template {
    uint16 category;
    string templateName;
    TemplateWarehouse templateWarehouse;
    
    constructor() public {
        templateWarehouse = TemplateWarehouse(0x9AFE6bf1DD7D653CD053a0F168edCadD4b98105F);
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
    function deployContract(uint16 _category, string _templateName) public returns (address deployedAddress) {
        string memory byteCode;
        uint16 status;
        
        (,byteCode,,,,,status) = templateWarehouse.getTemplate(_category, _templateName);
        // make sure template is approved
        require(status == 1);
        
        bytes memory c = bytes(byteCode);
        assembly {
          deployedAddress := create(0, add(c, 0x20), mload(c))
        }
        address deployed = deployedAddress;
        Template t = Template(deployed);
        t.initTemplateExternal(_category, templateName);
  }
}
