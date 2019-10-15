pragma solidity 0.4.25;

import "../../library/template.sol";
import "../../library/acl_slave.sol";
import "../pai_main.sol";

contract TestPaiDAO is Template, ACLSlave {
    uint public states = 0;
    PAIDAO public paiDAO;
    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        master = ACLMaster(_organizationContract);
    }


    //any diector can call this method.
    function plusOne() public auth("DIRECTOR") {
        states = states + 1;
    }

    //only director vote and Specialvote can call this method and need more than 3 director agree;
    function plusTwo() public auth("VOTE") 
    {
        states = states + 2;
    }

    // only standard vote can call this method and need more than 30% percent PIS stake agree;
    function plusThree() public auth("VOTE") 
    {
        states = states + 3;
    }

    //only director of this contract can call this method;
    function plusFour() public auth(StringLib.strConcat(StringLib.convertAddrToStr(this),"DIRECTOR")) 
    {
        states = states + 4;
    }
}