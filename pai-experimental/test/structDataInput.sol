pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/execution.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";


contract FakePAIIssuer is PAIIssuer {
    constructor() public {
        templateName = "Fake-Template-Name-For-Test";
    }
}

contract EXEC is Template, Execution {
    function() public payable {}
    address addr;
    mapping(uint => bytes) orders;
    uint orderIndex;
    struct inputBytes {
        bytes param;
    }
    function exec1(uint n) public {
        for(uint i = 1; i <= n;i++) {
            execute(addr,orders[i]);
        }
    }

    function setAddr(address _addr) public {
        addr = _addr;
    }

    function newOrder(bytes _param) public {
        orderIndex = orderIndex + 1;
        orders[orderIndex]= _param;
    }

    function newOrders(inputBytes[] memory _orders) public {
        if (0 == _orders.length)
            return;
        for(uint i = 0; i < _orders.length; i++) {
            newOrder(_orders[i].param);
        }
    }

    function newOrders2(bytes[] memory _orders) public {
        if (0 == _orders.length)
            return;
        for(uint i = 0; i < _orders.length; i++) {
            newOrder(_orders[i]);
        }
    }
}

contract Business is Template {
    uint public state = 0;

    function plus(uint num) public {
        state = state + num;
    }
}

contract InputTest is Template,DSTest {
    function testNoStruct() public {
        Business business = new Business();
        EXEC exec = new EXEC();
        //plus(uint num) num = 3
        exec.setAddr(business);
        exec.newOrder(hex"952700800000000000000000000000000000000000000000000000000000000000000003");
        exec.newOrder(hex"952700800000000000000000000000000000000000000000000000000000000000000004");
        exec.newOrder(hex"952700800000000000000000000000000000000000000000000000000000000000000005");
        exec.exec1(3);
        assertEq(business.state(),12);
    }

    function testStruct() public {
        Business business = new Business();
        EXEC exec = new EXEC();
        //plus(uint num) num = 3
        EXEC.inputBytes[] memory list = new EXEC.inputBytes[](3);
        EXEC.inputBytes temp;
        exec.setAddr(business);
        temp.param = hex"952700800000000000000000000000000000000000000000000000000000000000000003";
        list[0] = temp;
        temp.param = hex"952700800000000000000000000000000000000000000000000000000000000000000004";
        list[1] = temp;
        temp.param = hex"952700800000000000000000000000000000000000000000000000000000000000000005";
        list[2] = temp;
        exec.newOrders(list);
        exec.exec1(3);
        assertEq(business.state(),12);
    }

    function testStruct2() public {
        Business business = new Business();
        EXEC exec = new EXEC();
        //plus(uint num) num = 3
        bytes[] memory list = new bytes[](3);
        bytes memory temp;
        exec.setAddr(business);
        temp = hex"952700800000000000000000000000000000000000000000000000000000000000000003";
        list[0] = temp;
        temp = hex"952700800000000000000000000000000000000000000000000000000000000000000004";
        list[1] = temp;
        temp = hex"952700800000000000000000000000000000000000000000000000000000000000000005";
        list[2] = temp;
        exec.newOrders2(list);
        exec.exec1(3);
        assertEq(business.state(),12);
    }

   
}
