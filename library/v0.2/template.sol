pragma solidity 0.4.25;

contract Template {
    uint16 category;
    string templateName;
    
    function initTemplate(uint16 _category, string _templateName) public {
        require(msg.sender == 0xf1512CCD48Bf5b352f2b44482afB37E22aAD3892);
        category = _category;
        templateName = _templateName;
    }
    
    function getTemplateInfo() public view returns (uint16, string){
        return (category, templateName);
    }
}