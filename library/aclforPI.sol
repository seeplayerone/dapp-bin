pragma solidity 0.4.25;
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";

contract ACL is DSMath,Template {

    bool disableACL; //attention!!!!! this parameter is only can be set to true in testcase
    mapping(uint => bytes) roles;
    mapping(bytes => PermissionGroup) groups;
    struct PermissionGroup {
        bool exist;
        bytes superior;
        address[] members;
    }
    uint indexForACL;
    string constant ADMIN = "ADMIN";

    constructor() public {
        indexForACL = 1;
        roles[indexForACL] = bytes(ADMIN);
        groups[bytes(ADMIN)].exist = true;
        groups[bytes(ADMIN)].superior = bytes(ADMIN);
        groups[bytes(ADMIN)].members.push(msg.sender);
    }
    
    function createNewRole(bytes newRole, bytes superior) public auth(ADMIN) {
        require(!groups[newRole].exist);
        if(!groups[superior].exist) {
            indexForACL = add(indexForACL,1);
            roles[indexForACL] = superior;
            groups[superior].exist = true;
            groups[superior].superior = bytes(ADMIN);
        }
        indexForACL = add(indexForACL,1);
        roles[indexForACL] = newRole;
        groups[newRole].exist = true;
        groups[newRole].superior = superior;
    }

    function addMember(address _addr, bytes role) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        require(!addressExist(role,_addr));
        groups[role].members.push(_addr);
    }

    function removeMember(address _addr, bytes role) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        uint len = groups[role].members.length;
        if(0 == len) {
            return;
        }
        for(uint i = 0; i < len; i++) {
            if(_addr == groups[role].members[i]) {
                if(i != len - 1) {
                    groups[role].members[i] = groups[role].members[len - 1];
                }
            groups[role].members.length--;
            }
        }
    }

    function changeSuperior(bytes role, bytes newSuperior) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        if(!groups[newSuperior].exist) {
            indexForACL = indexForACL + 1;
            roles[indexForACL] = newSuperior;
            groups[newSuperior].exist = true;
            groups[newSuperior].superior = groups[role].superior;
        }
        groups[role].superior = newSuperior;
    }

    function addressExist(bytes role, address _addr) public view returns (bool) {
        for(uint i = 0; i < groups[role].members.length; i++) {
            if(_addr == groups[role].members[i]) {
                return true;
            }
        }
        return false;
    }

    function getSuperior(bytes role) public view returns (string) {
        return string(groups[role].superior);
    }

    function getMembers(bytes role) public view returns (address[]) {
        return groups[role].members;
    }

    modifier auth(string role) {
        canPerform(role, msg.sender);
        _;
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        if (disableACL) {
            return true;
        }
        return addressExist(bytes(role), _addr);
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        if (disableACL) {
            return true;
        }
        return addressExist(role, _addr);
    }

    // only for debug;
    function roleExist(bytes role) public view returns (bool) {
        return groups[role].exist;
    }
    
    function creatNewRoleByString(string newRole, string superior) public {
        createNewRole(bytes(newRole), bytes(superior));
    }

    function roleExistByString(string role) public view returns (bool) {
        return roleExist(bytes(role));
    }

    function addMemberByString(address _addr, string role) public {
        addMember(_addr, bytes(role));
    }

    function removeMemberByString(address _addr, string role) public {
        removeMember(_addr, bytes(role));
    }

    function leaveRoleByString(string role) public {
        removeMember(msg.sender, bytes(role));
    }

    function changeSuperiorByString(string role, string newSuperior) public {
        changeSuperior(bytes(role), bytes(newSuperior));
    }

    function addressExistByString(string role, address _addr) public view returns (bool) {
        return addressExist(bytes(role), _addr);
    }

    function getSuperiorByString(string role) public view returns (string) {
        return getSuperior(bytes(role));
    }

    function getMembersByString(string role) public view returns (address[]) {
        return getMembers(bytes(role));
    }
}