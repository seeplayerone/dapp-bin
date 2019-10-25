pragma solidity 0.4.25;

contract Person{
    uint public age = 10;
    string public name = "dandan";
    string public lastname = "ma";
     
    
    function updatename(string _name,uint _age, string _lastname) public {
        name = _name;
        lastname = _lastname;
        age = _age;
    }
    
    function updateage(uint _age) public {
        age = _age;
    }
}


contract CallTest{

    function testname() public returns (string){

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updatename(string)"));
        addr.call(methodId,"jack");

        return Person(addr).name();
    }

    function testnamebytes() public returns (string,string,uint) {
        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updatename(string,uint256,string)"));
        bytes memory param = abi.encode("jack",6,"xu");
        addr.call(abi.encodePacked(methodId, param));

        return (Person(addr).name(),Person(addr).lastname(),Person(addr).age());
    }

    function testage() public returns (uint){

        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updateage(uint256)"));
        addr.call(methodId,999);

        return Person(addr).age();
    }

    // function testInvokeMethod() returns (string) {
    //     address addr = new Person();

    //     // bytes4 methodId = bytes4(keccak256("updatename(string)"));
    //     // addr.call(abi.encodeWithSelector(methodId,"jack"));

    //     addr.call(hex"d834756d000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000046a61636b00000000000000000000000000000000000000000000000000000000");

    //     return Person(addr).name();
    // }

    // function testInvokeMethod2() returns (string) {
    //     address addr = new Person();

    //     // bytes4 methodId = bytes4(keccak256("updatename(string)"));
    //     // addr.call(abi.encodeWithSelector(methodId,"jack"));
    //     bytes memory param =
    //     hex"d834756d000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000046a61636b00000000000000000000000000000000000000000000000000000000";

    //     return Person(addr).name();
    // }
}
