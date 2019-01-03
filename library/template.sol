pragma solidity 0.4.25;

contract Template {
    uint16 public category;
    string public parent;
    
    constructor(uint16 _category, string _parent) public {
        category = _category;
        parent = _parent;
    }
}