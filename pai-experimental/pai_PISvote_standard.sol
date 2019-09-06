pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/string_utils.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/vote.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/pai_main.sol";

/// interface....
/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteStandard is BasicVote {
    using StringLib for string;
    
    /// params to be init
    PAIDAO public paiDAO;

    ///
    struct funcData {
        uint startProportion;
        uint passProportion;
        bytes4 _func;
        bytes _param;
    }
    mapping(uint => funcData) voteFuncData;

    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        voteFuncData[1].startProportion = RAY / 1000;
        voteFuncData[1].passProportion = RAY * 3 / 10;
        voteFuncData[1]._func = hex"4b28ad80";
        voteFuncData[1]._param = hex"";
    }

    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(msg.sender == address(this) ||
                paiDAO.canPerform(msg.sender, func));
        _;
    }
 
    function startVote(
         string _subject,
           uint _totalVotes,
           uint _duration,
        address _targetContract,
           uint funcIndex,
           uint voteNumber
        )
        public
        authFunctionHash("VOTEMANAGER")
        returns (uint)
    {
        //require funcIndex exist;
        require(voteNumber >= rmul(_totalVotes,voteFuncData[funcIndex].startProportion),"not enough weights to start a vote");
        uint voteId = startVoteInternal(_subject, rmul(_totalVotes, voteFuncData[funcIndex].passProportion), _totalVotes,
                                        timeNow(), add(timeNow(),_duration), _targetContract,
                                        voteFuncData[funcIndex]._func, voteFuncData[funcIndex]._param);
        voteInternal(voteId,true,voteNumber);
        return voteId;
    }

    function vote(uint voteId, bool attitude, uint voteNumber) public authFunctionHash("VOTEMANAGER") {
        voteInternal(voteId, attitude, voteNumber);
    }
}