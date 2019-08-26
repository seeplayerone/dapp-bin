pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/pai_main.sol";

contract TestPaiDAO is Template {
    uint public states = 0;
    PAIDAO public paiDAO;
    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
    }

    modifier authFunctionHash(string func) {
        require(msg.sender == address(this) ||
                paiDAO.canPerform(msg.sender, func));
        _;
    }

    //any diector can call this method.
    function plusOne() public authFunctionHash("DIRECTOR") {
        states = states + 1;
    }

    //only director vote and Specialvote can call this method and need more than 3 director agree;
    function plusTwo() public authFunctionHash("VOTE") 
    {
        states = states + 2;
    }

    // only standard vote can call this method and need more than 30% percent PIS stake agree;
    function plusThree() public authFunctionHash("VOTE") 
    {
        states = states + 3;
    }

    //only director of this contract can call this method;
    function plusFour() public authFunctionHash(StringLib.strConcat(StringLib.convertAddrToStr(this),"DIRECTOR")) 
    {
        states = states + 4;
    }
}