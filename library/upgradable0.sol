pragma solidity 0.4.25;

contract Upgradable0 {
    
    string name;
    
    function setName(string _name) public {
        name = _name;
    }
    
    function getName() public returns (string) {
        return name;
    } 
    
}
15:33
