pragma solidity 0.4.25;

import "./gov_election_base.sol";

contract PAIElectionDirector is PAIElectionBase {

    constructor(address pisContract, string winnerRole, string backupRole) 
        //PAIElectionBase(pisContract, "PAI-DIRECTOR", "PAI-DIRECTOR-BACKUP") 
        PAIElectionBase(pisContract, winnerRole, backupRole)
        public {}

    function addDirector() public {
        address[] memory backup = master.getMembers(bytes(BACKUP));
        uint len = backup.length;
        if(0==len)
            return;
        master.addMember(backup[len-1],bytes(WINNER));
        master.removeMember(backup[len-1],bytes(BACKUP));
    }
}