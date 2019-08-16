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
    function vote(uint voteId, bool attitude) external;
}


/// @title This is a simple vote contract, everyone has the same vote weights
/// @dev Every template contract needs to inherit Template contract directly or indirectly
contract PISVotePower is Template, DSMath {
    using StringLib for string;
    
    /// params to be init
    PAIDAO paiDAO;
    uint96 voteAssetGlobalId;
 
    
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

    function voteTo(address _vote, uint voteId, bool attitude) public {
        Vote(_vote).vote(voteId, attitude);
    }
}




