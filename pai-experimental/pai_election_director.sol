pragma solidity 0.4.25;

import "./pai_election_base.sol";

contract PAIElectionDirector is PAIElectionBase {

    constructor(address pisContract) 
        PAIElectionBase(pisContract, "PAI-DIRECTOR", "PAI-DIRECTOR-BACKUP") 
        public { }
}