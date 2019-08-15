pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract vote is Template {

    function invokeOrganizationContract(bytes4 _func, bytes _param) public {
        address tempAddress = 0x63537439c8c73d51e6a17e404ba09768f13ad4569c;
        uint paramLength = _param.length;
        uint totalLength = 4 + paramLength;

        assembly {
            let p := mload(0x40)
            mstore(p, _func)
            for { let i := 0 } lt(i, paramLength) { i := add(i, 32) } {
                mstore(add(p, add(4,i)), mload(add(add(_param, 0x20), i)))
            }
            let success := call(not(0), tempAddress, 0, 0, p, totalLength, 0, 0)

            let size := returndatasize
            returndatacopy(p, 0, size)

            switch success
            case 0 {
                revert(p, size)
            }
            default {
                return(p, size)
            }
        }
    } 
}




