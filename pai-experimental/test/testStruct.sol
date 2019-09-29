pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

contract DD {
    struct DAD {
        uint x;
        uint y;
    }

    uint public dd;

    function setDad(DAD[] dads) public {
        for(uint i = 0; i < dads.length; i ++) {
            dd = dd + dads[i].x;
            dd = dd + dads[i].y;
        }
    }
}

contract FakePerson {
    function() public payable {}
    
    function execute(address target, bytes4 selector, bytes params) returns (bool) {
        return target.call(abi.encodePacked(selector, params));
    }
}

contract test {
    function testDD() returns (uint){
        DD tt = new DD();
        FakePerson fp = new FakePerson();

        DD.DAD[] memory dds = new DD.DAD[](2);
        dds[0].x = 1;
        dds[1].x = 2;

        fp.execute(
            address(tt),
            tt.setDad.selector,
            abi.encode(dds)
        );

        return tt.dd();
    }
}
