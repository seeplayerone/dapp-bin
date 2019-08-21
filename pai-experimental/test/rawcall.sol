pragma solidity 0.4.25;

contract Person{
    uint public age = 10;
    string public name = "dandan";
     
    
    function updatename(string _name) public {
        name = _name;
    }
    
    function updateage(uint _age) public {
        age = _age;
    }



}


contract CallTest{
    

    function testname() returns (string){

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updatename(string)"));
        addr.call(methodId,"jack");

        return Person(addr).name();
    }

    function testnamebytes() returns (string) {
        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updatename(string)"));
        addr.call(abi.encodeWithSelector(methodId,"jack"));

        return Person(addr).name();
    }

    function testage() returns (uint){

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updateage(uint256)"));
        addr.call(methodId,999);

        return Person(addr).age();
    }
}
