pragma solidity 0.4.25;

import "./utils/ds_math.sol";

/**
    ACL Master/Slave provides a basic structure for permission control.

    We can define Permission Group in ACL Master. A PG contains a list of addresses and a Superior which is also a PG.
    A PG is managed by addresses defined in its Superior PG.
 */

contract ACLMaster is DSMath {
    struct PermissionGroup {
        bool exist;
        bool canQuit;
        address[] members;
        bytes superior;
        uint32 memberLimit; // most of addresses this PG can have; 0 represents unlimited
    }

    mapping(uint => bytes) public roles;
    mapping(bytes => PermissionGroup) groups;

    uint public indexOfPG;
    string public TOPADMIN = "ADMIN";

    constructor() public {
        indexOfPG = 1;
        roles[indexOfPG] = bytes(TOPADMIN);
        groups[bytes(TOPADMIN)].exist = true;
        groups[bytes(TOPADMIN)].superior = bytes(TOPADMIN);
        groups[bytes(TOPADMIN)].members.push(msg.sender);
    }
    
    function createNewRole(bytes newRole, bytes superior, uint32 limit, bool canQuit) public auth(TOPADMIN) {
        require(!groups[newRole].exist);
        require(groups[superior].exist);

        indexOfPG = add(indexOfPG,1);
        roles[indexOfPG] = newRole;
        groups[newRole].exist = true;
        groups[newRole].canQuit = canQuit;
        groups[newRole].superior = superior;
        groups[newRole].memberLimit = limit;
    }

    function changeTopAdmin(string newAdmin) public auth(TOPADMIN) {
        require(groups[bytes(newAdmin)].exist);
        TOPADMIN = newAdmin;
    }

    function addMember(address _addr, bytes role) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        require(!addressExist(role,_addr));
        require(0 == groups[role].memberLimit || groups[role].members.length < groups[role].memberLimit);
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
                return;
            }
        }
    }

    function quit(bytes role) public {
        require(groups[role].exist);
        require(groups[role].canQuit);
        uint len = groups[role].members.length;
        if(0 == len) {
            return;
        }
        for(uint i = 0; i < len; i++) {
            if(msg.sender == groups[role].members[i]) {
                if(i != len - 1) {
                    groups[role].members[i] = groups[role].members[len - 1];
                }
                // delete groups[role].members[len - 1];
                groups[role].members.length--;
                return;
            }
        }
    }

    function resetMembers(address[] _members, bytes role) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        require(0 == groups[role].memberLimit || _members.length <= groups[role].memberLimit);
        groups[role].members.length = 0;
        if (_members.length > 0) {
            for (uint i = 0; i < _members.length; i++) {
                groups[role].members.push(_members[i]);
            }
        }
    }

    function changeSuperior(bytes role, bytes newSuperior) public {
        require(groups[role].exist);
        require(groups[newSuperior].exist);
        require(canPerform(groups[groups[role].superior].superior, msg.sender) || canPerform(TOPADMIN, msg.sender));
        groups[role].superior = newSuperior;
    }

    function changeMemberLimit(bytes role, uint32 newlimit) public {
        require(groups[role].exist);
        require(canPerform(groups[role].superior, msg.sender));
        groups[role].memberLimit = newlimit;
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

    function getMemberLimit(bytes role) public view returns (uint32) {
        return groups[role].memberLimit;
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        return addressExist(bytes(role), _addr);
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        return addressExist(role, _addr);
    }

    modifier auth(string role) {
        require(canPerform(role, msg.sender));
        _;
    }
}