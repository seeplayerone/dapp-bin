pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";

contract BankAssistant is Template,  ACLSlave {
    string director = "Director@Bank";
    string auditor = "Auditor@Bank";
    constructor(address paiMainContract) public
    {
        master = ACLMaster(paiMainContract);
    }
    function impeachDirector(address addr) public auth("ImpeachmentVote@Bank") {
        master.removeMember(addr, bytes(director));
    }

    function addAuditorByCEO(address addr) public auth("CEO@Bank") {
        master.addMember(addr, bytes(auditor));
    }

    function removeAuditorByCEO(address addr) public auth("CEO@Bank") {
        master.removeMember(addr, bytes(auditor));
    }

    function resetAuditorsByCEO(address[] addrs) public auth("CEO@Bank") {
        master.resetMembers(addrs, bytes(auditor));
    }

    function addAuditorByDirector(address addr) public auth("Director@Bank") {
        master.addMember(addr, bytes(auditor));
    }

    function removeAuditorByDirector(address addr) public auth("Director@Bank") {
        master.removeMember(addr, bytes(auditor));
    }

    function resetAuditorsByDirector(address[] addrs) public auth("Director@Bank") {
        master.resetMembers(addrs, bytes(auditor));
    }
}