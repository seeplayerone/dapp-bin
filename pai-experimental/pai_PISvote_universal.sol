pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/library/string_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/vote.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";

/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVoteUniversal is BasicVote {
    using StringLib for string;
    
    /// params to be init
    PAIDAO paiDAO;
    uint96 voteAssetGlobalId;

    /// vote param
    uint passPercentage = RAY / 2;
    uint startPercentage = RAY / 1000;

    function setOrganization(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
        (,voteAssetGlobalId) = paiDAO.getAdditionalAssetInfo(0);
    }

    /// get the organization contract address
    function getOrganization() public view returns (address) {
        return paiDAO;
    }

    function getVoteAssetGlobalId() public view returns (uint) {
        return voteAssetGlobalId;
    }

    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(paiDAO.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this),func)));
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
    {
        require(voteNumber > rmul(_totalVotes,startPercentage),"not enough weights to start a vote");
        uint voteid = startVoteInternal(_subject, rmul(_totalVotes, passPercentage), _totalVotes,
                                        block.timestamp, add(block.timestamp,_duration), _targetContract, _func, _param);
        voteInternal(voteid,true,voteNumber);
    }

    function vote(uint voteId, bool attitude, uint voteNumber) public {
        voteInternal(voteId, attitude, voteNumber);
    }
}




