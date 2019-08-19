pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/vote.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

/// interface....
/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteUniversal is BasicVote {
    using StringLib for string;
    
    /// params to be init
    PAIDAO paiDAO;

    /// vote param
    uint passProportion;
    uint startProportion;

    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        passProportion = RAY / 2;
        startProportion = RAY / 1000;
    }

    /// get the organization contract address
    function getOrganization() public view returns (address) {
        return paiDAO;
    }

    function setPassProportion(uint _new) public authFunctionHash("SetParam") {
        passProportion = _new;
    }

    function setStartProportion(uint _new) public authFunctionHash("SetParam") {
        startProportion = _new;
    }

    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(msg.sender == address(this) ||
                paiDAO.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this),func)));
        _;
    }
 
    function startVote(
         string _subject,
           uint _totalVotes,
           uint _duration,
        address _targetContract,
         bytes4 _func,
          bytes _param,
           uint voteNumber
        )
        public
        //authFunctionHash("Vote")
    {
        require(voteNumber >= rmul(_totalVotes,startProportion),"not enough weights to start a vote");
        uint voteid = startVoteInternal(_subject, rmul(_totalVotes, passProportion), _totalVotes,
                                        block.timestamp, add(block.timestamp,_duration), _targetContract, _func, _param);
        voteInternal(voteid,true,voteNumber);
    }

    function vote(uint voteId, bool attitude, uint voteNumber) public {
    //function vote(uint voteId, bool attitude, uint voteNumber) public authFunctionHash("Vote") {
        voteInternal(voteId, attitude, voteNumber);
    }

    //only for debug
    function getPassProportion() public view returns (uint) {
        return passProportion;
    }

    function getStartProportion() public view returns (uint) {
        return startProportion;
    }
}