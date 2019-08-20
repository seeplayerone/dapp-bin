pragma solidity 0.4.25;

contract Person{
    uint age = 10;
     
    
    function increaseAge(string name, uint num) returns (uint){
        return ++age;
    }
    
    function getAge() returns (uint){
        return age;
    }

}


contract CallTest{
    
    function callnoreturn() {

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("increaseAge(string,uint256)"));
        bool result = addr.call(methodId,"jack", 1);
    }

    function callreturn() returns (bool) {

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("increaseAge(string,uint256)"));
        return addr.call(methodId,"jack", 1);
    }

}
