pragma solidity 0.4.25;
import "github.com/evilcc2018/dapp-bin/library/template.sol";

contract TestGroup is Template {

    address[] group;

    function addMember(address _addr) public {
        if(Exist(_addr)) {
            return;
        }
        group.push(_addr);
    }

    function removeMember(address _addr, bytes role) public {
        if(!Exist(_addr)) {
            return;
        }
        uint len = group.length;
        if(0 == len) {
            return;
        }
        for(uint i = 0; i < len; i++) {
            if(_addr == group[i]) {
                if(i != len - 1) {
                    group[i] = group[len - 1];
                }
            delete group[len-1];
            group.length--;
            }
        }
    }

    function Exist(address _addr) public view returns (bool) {
        for(uint i = 0; i < group.length; i++) {
            if(_addr == group[i]) {
                return true;
            }
        }
        return false;
    }


    function seeAllMembers() public view returns(address[]) {
        return group[];
    }
}