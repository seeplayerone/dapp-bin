pragma solidity 0.4.25;

contract BalanceOf {
    uint amount;
    uint assettype;

    address private hole = 0x660000000000000000000000000000000000000000;    

    function test() public payable {
        amount = msg.value / 2;
        assettype = msg.assettype;
        hole.transfer(amount, msg.assettype);
    }

    function check() public view returns (uint, uint){
        return (amount, flow.balance(this, assettype));
    }
}