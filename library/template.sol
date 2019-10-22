pragma solidity 0.4.25;

import "./utils/string_utils.sol";

interface TemplateWarehouse{
    function getTemplate(uint16 _category, string name) external returns(string, bytes, uint, uint8, uint8, uint8, uint16);
}

/// @title This is the base contract any other contracts must directly or indirectly inherit to run on Asimov platform
///  Asimov only accepts a template rather than a randomly composed Solidity contract
///  An Asimov template always belongs to a given category and has a unique template name in the category
contract Template {
    /// @dev should set to private to improve security SECURITY ISSUE!
    uint16 internal category;
    string internal templateName;

    bool initialized = false;
    
    /// @dev initialize a template
    ///  it was originally the logic inside the constructor
    ///  it is changed in such way to provide a better user experience in the Asimov debugging tool
    /// @param _category category of the template
    /// @param _templateName name of the template
    function initTemplate(uint16 _category, string _templateName) public {
        require(!initialized);
        category = _category;
        templateName = _templateName;
        initialized = true;
    }

    /// @dev get the template information
    function getTemplateInfo() public view returns (uint16, string){
        return (category, templateName);
    }

}
