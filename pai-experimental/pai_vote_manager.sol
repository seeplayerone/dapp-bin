pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

// import "./3rd/math.sol";
// import "./string_utils.sol";
// import "./template.sol";
// import "./pai_main.sol";
interface Vote {
    function vote(uint voteId, bool attitude, uint voteNumber) external;
    function startVote(
         string _subject,
           uint _totalVotes,
           uint _duration,
        address _targetContract,
         bytes4 _func,
          bytes _param,
           uint voteNumber
        )
        external
        returns (uint);
    function startVote(
         string _subject,
           uint _totalVotes,
           uint _duration,
        address _targetContract,
           uint funcIndex, 
           uint voteNumber
        )
        external
        returns (uint);
    function getVoteEndTime(uint voteId) external returns (uint);
}

interface VoteS {
    function vote(uint voteId, bool attitude, uint voteNumber) external;

    function getVoteEndTime(uint voteId) external returns (uint);
}


/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteManager is Template, DSMath {
    using StringLib for string;
    
    /// params to be init
    PAIDAO public paiDAO;
    uint96 public voteAssetGlobalId;
    
    mapping(address => uint) public balanceOf;

    struct voteInfo {
        address voteContract;
        uint voteId;
        uint voteNumber;
        uint finishTime;
    }

    mapping(address => voteInfo[]) voteStates;
    constructor(address organization) public {
        paiDAO = PAIDAO(organization);
        (,voteAssetGlobalId) = paiDAO.Token(0);
    }

    function deposit() public payable {
        require(msg.assettype == voteAssetGlobalId, "Only PIS can get vote power");
        balanceOf[msg.sender] = add(balanceOf[msg.sender], msg.value);
    }

    function withdraw(uint amount) public {
        uint mostVote;
        (mostVote,) = getMostVote(msg.sender);
        uint withdrawLimit = sub(balanceOf[msg.sender],mostVote);
        require(withdrawLimit >= amount, "not enough balance or some PIS is still in vote process");
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],amount);
        msg.sender.transfer(amount, voteAssetGlobalId);
    }

    function startVoteTo(
        address _voteContract,
         string _subject,
           uint _duration,
        address _targetContract,
         bytes4 _func,
          bytes _param,
           uint _voteNumber
        )
        public
    {
        require(_voteNumber <= balanceOf[msg.sender], "not enough vote power");
        uint _totalVotes;
        (,,,,,_totalVotes) = paiDAO.getAssetInfo(0);
        uint voteId = Vote(_voteContract).startVote(_subject, _totalVotes, _duration, _targetContract, _func, _param, _voteNumber);
        voteInfo memory v;
        v.voteContract = _voteContract;
        v.voteId = voteId;
        v.voteNumber = _voteNumber;
        v.finishTime = Vote(_voteContract).getVoteEndTime(voteId);
        voteStates[msg.sender].push(v);
    }
    
    function startVoteToStandard(
        address _voteContract,
         string _subject,
           uint _duration,
        address _targetContract,
           uint _funcIndex,
           uint _voteNumber
        )
        public
    {
        require(_voteNumber <= balanceOf[msg.sender], "not enough vote power");
        uint _totalVotes;
        (,,,,,_totalVotes) = paiDAO.getAssetInfo(0);
        uint voteId = Vote(_voteContract).startVote(_subject, _totalVotes, _duration, _targetContract, _funcIndex, _voteNumber);
        voteInfo memory v;
        v.voteContract = _voteContract;
        v.voteId = voteId;
        v.voteNumber = _voteNumber;
        v.finishTime = Vote(_voteContract).getVoteEndTime(voteId);
        voteStates[msg.sender].push(v);
    }

    function voteTo(address _voteContract, uint _voteId, bool attitude, uint _voteNumber) public {
        Vote(_voteContract).vote(_voteId, attitude, _voteNumber);
        bool exist;
        uint index;
        (exist,index) = voteExist(msg.sender, _voteContract, _voteId);
        if (exist) {
            voteStates[msg.sender][index].voteNumber = add(voteStates[msg.sender][index].voteNumber, _voteNumber);
            require(voteStates[msg.sender][index].voteNumber <= balanceOf[msg.sender],"not enough vote power");
        } else {
            require(_voteNumber <= balanceOf[msg.sender], "not enough vote power");
            voteInfo memory v;
            v.voteContract = _voteContract;
            v.voteId = _voteId;
            v.voteNumber = _voteNumber;
            v.finishTime = Vote(_voteContract).getVoteEndTime(_voteId);
            voteStates[msg.sender].push(v);
        }
    }

    function getMostVote(address _addr) public returns (uint,uint) {
        uint len = voteStates[_addr].length;
        if (0 == len)
            return (0,0);
        uint mostVoteNumber = 0;
        uint index = 0;
        for(uint i = 0; i < len;) {
            voteInfo storage v = voteStates[_addr][i];
            if (v.finishTime > 0) {
                v.finishTime = Vote(v.voteContract).getVoteEndTime(v.voteId);
            }
            if (v.finishTime > 0) {
                if (v.voteNumber > mostVoteNumber) {
                    mostVoteNumber = v.voteNumber;
                    index = i;
                    i++;
                }
            } else {
                if(i != len - 1) {
                    voteStates[_addr][i] = voteStates[_addr][len - 1];
                }
                delete voteStates[_addr][len - 1];
                voteStates[_addr].length--;
                len--;
            }
        }
        return (mostVoteNumber,index);
    }
    
    function voteExist(address _addr, address _voteContract, uint _voteId) public view returns (bool, uint) {
        uint len = voteStates[_addr].length;
        for(uint i = 0; i < len; i++){
            voteInfo storage v = voteStates[_addr][i];
            if(_voteContract == v.voteContract && _voteId == v.voteId){
                return (true,i);
            }
        }
        return (false,0);
    }

    function getVoteInfo(address _addr,uint i) public view returns (address,uint,uint,uint) {
        return(
            voteStates[_addr][i].voteContract,
            voteStates[_addr][i].voteId,
            voteStates[_addr][i].voteNumber,
            voteStates[_addr][i].finishTime
        );
    }
}




