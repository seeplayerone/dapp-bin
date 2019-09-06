pragma solidity 0.4.25;

contract Person{
    uint public age = 10;
    string public name = "dandan";
    string public lastname = "ma";
     
    
    function updatename(string _name, string _lastname) public {
        name = _name;
        lastname = _lastname;
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

    function testnamebytes() returns (string,string) {
        address addr = new Person();

        bytes4 methodId = bytes4(keccak256("updatename(string,string)"));
        bytes param = abi.encodeParameters(["string","string"],["jack","xu"]);
        addr.call(abi.encodeWithSelector(methodId,param));

        return (Person(addr).name(),Person(addr).lastname());
    }

    function testage() returns (uint){

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
