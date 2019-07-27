pragma solidity 0.4.25;

//import "../SafeMath.sol";
//import "../acl.sol";
//import "../template.sol";

import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";
import "github.com/seeplayerone/dapp-bin/library/acl.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";


/// @dev this is a sample roll contract
///  DO NOT TAKE IT SERIOUSLY !!!

contract AsiRoll is ACL, Template {

    using SafeMath for *;

    string constant ADMIN_FUNCTIONS = "ADMIN_FUNCTIONS";

    uint private balance;
    uint private roll;
    uint private win;
    uint private lucky;

    uint96 constant ASIM = 0x000000000000; 

    event Played(uint, uint, uint);

    constructor() public payable {
        configureFunctionAddressInternal(ADMIN_FUNCTIONS, msg.sender, OpMode.Add);
        deposit();
    }

    function() public payable authFunctionHash(ADMIN_FUNCTIONS) {
        deposit();
    }

    function deposit() public payable authFunctionHash(ADMIN_FUNCTIONS) {
        if(msg.value > 0) {
            require(msg.assettype == ASIM);
        }
        balance = SafeMath.add(balance, msg.value);
    }

    function withdraw() public authFunctionHash(ADMIN_FUNCTIONS) {
        require(balance > 0);
        msg.sender.transfer(balance, ASIM);
        balance = 0;       
    }

    function play(uint luckyGUESS) public payable {
        lucky = luckyGUESS;

        require(lucky > 0);
        require(lucky < 101);
        
        uint asset = msg.assettype;
        uint value = msg.value;

        require(balance > 0);
        if(value > 0) {
            require(msg.assettype == ASIM);            
        }

        balance = SafeMath.add(balance, msg.value);

        roll = random();

        /// u win
        if(lucky > roll) {
            win = SafeMath.div(SafeMath.mul(value, 100), lucky);
            if(win < balance) {            
                msg.sender.transfer(win, asset);
                balance = SafeMath.sub(balance, win);
            } else {
                msg.sender.transfer(balance, asset);
                balance = 0;
            }
        } else {
            win = 0;
        }

        emit Played(luckyGUESS, roll, win);
    }

    /// random algorithm from FOMO3D
    function random() private view returns (uint) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));

        return SafeMath.mod(seed, 100);
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function getLastRoll() public view returns (uint) {
        return roll;
    }

    function getLastWin() public view returns (uint) {
        return win;
    }

    function getLastLucky() public view returns (uint) {
        return lucky;
    }

}