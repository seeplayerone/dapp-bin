pragma solidity 0.4.25;

//import "github.com/seeplayerone/dapp-bin/library/string_utils.sol";
import "./string_utils.sol";

interface TemplateWarehouse{
    function getTemplate(uint16 _category, string name) external returns(string, bytes, uint, uint8, uint8, uint8, uint16);
}

/// @title This is the base contract any other contracts must directly or indirectly inherit to run on Flow platform
///  Flow only accepts a template rather than a randomly composed Solidity contract
///  A Flow template always belongs to a given category and has a unique template name in the category
contract Template {
    uint16 internal category;
    string internal templateName;
    
    /// @dev initialize a template
    ///  it was originally the logic inside the constructor
    ///  it is changed in such way to provide a better user experience in the Flow debugging tool
    function initTemplate(uint16 _category, string _templateName) public {
        require(msg.sender == 0x66dbdd2826fb068f2929af065b04c0804d0397b09e);
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

}
