pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/vote.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

/// interface....
/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract DirectorVote is BasicVote {
    using StringLib for string;
    
    /// params to be init
    PAIDAO public paiDAO;
    uint public passProportion;
    uint public startProportion;
    uint totalDirectors = 7;

    ///
    struct funcData {
        uint passNumber;
        bytes4 _func;
        bytes _param;
    }
    mapping(uint => funcData) voteFuncData;

    mapping(uint => address[]) alreadyVoted;

    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        voteFuncData[1].passNumber = 3;
        voteFuncData[1]._func = hex"42eca434";
        voteFuncData[1]._param = hex"";
        passProportion = RAY / 2;
        startProportion = RAY / 1000;
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
           uint _duration,
        address _targetContract,
           uint funcIndex
        )
        public
        authFunctionHash("DIRECTOR")
        returns (uint)
    {
        //require funcIndex exist;
        uint voteId = startVoteInternal(_subject, voteFuncData[funcIndex].passNumber, totalDirectors,
                                        timeNow(), add(timeNow(),_duration), _targetContract,
                                        voteFuncData[funcIndex]._func, voteFuncData[funcIndex]._param);
        voteInternal(voteId,true,1);
        alreadyVoted[voteId].push(msg.sender);
        return voteId;
    }

    function vote(uint voteId, bool attitude) public
    authFunctionHash("DIRECTOR") 
    {
        require(!checkVoted(voteId,msg.sender),"already voted");
        voteInternal(voteId, attitude, 1);
        alreadyVoted[voteId].push(msg.sender);
    }

    function checkVoted(uint voteId, address addr) public view returns (bool) {
        uint len = alreadyVoted[voteId].length;
        if (0 == len)
            return false;
        for(uint i = 0; i < len; i++) {
            if (addr == alreadyVoted[voteId][i])
                return true;
        }
        return false;
    }
}