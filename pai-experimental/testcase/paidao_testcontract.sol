pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";

contract TestPaiDAO is Template {
    uint public states = 0;
    modifier authFunctionHash(string func) {
        require(msg.sender == address(this) ||
                paiDAO.canPerform(msg.sender, func));
        _;
    }

    function plusOne() public authFunctionHash("DIRECTOR") {
        states = states + 1;
    }

    function plusTwo() public authFunctionHash("VOTE") {
        states = states + 2;
    }

    function plusThree() public authFunctionHash("VOTE") {
        states = states + 3;
    }

    function plusFour() public authFunctionHash(StringLib.strConcat(StringLib.convertAddrToStr(this),func("DIRECTOR")) {
        states = states + 4;
    }
}