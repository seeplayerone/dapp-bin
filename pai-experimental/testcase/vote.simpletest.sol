pragma solidity 0.4.25;
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/vote.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";



contract VoteSample is Template, BasicVote {

    function startVote(address addr) public {
        startVoteInternal("AA",100,200,block.timestamp, block.timestamp + 10 days,addr,
            bytes4(keccak256("plus(uint256)")),abi.encode(10));
    }

    function startVote2(address addr) public {
        bytes memory param = abi.encode(12,14);
        startVoteInternal("BB",100,200,block.timestamp, block.timestamp + 10 days,addr,
            bytes4(keccak256("plus2(uint256,uint256)")),param);
    }

    function VoteTo(uint voteId) public{
        voteInternal(voteId,true,50);
    }

}

contract Business is Template {
    uint public state = 0;

    function plus(uint num) public {
        state = state + num;
    }

    function plus2(uint num1,uint num2) public {
        state = state + num1 + num2;
    }

}

contract VoteTest is Template,DSTest {
    Business bb;
    VoteSample vote;
    function simpleTest() public {
        bb = new Business();
        vote = new VoteSample();
        assertEq(bb.state(),0);
        vote.startVote(bb);
        vote.VoteTo(1);
        vote.VoteTo(1);
        vote.invokeVoteResult(1);
        assertEq(bb.state(),10);
        vote.startVote2(bb);
        vote.VoteTo(2);
        vote.VoteTo(2);
        vote.invokeVoteResult(2);
        assertEq(bb.state(),36);
    }   
}