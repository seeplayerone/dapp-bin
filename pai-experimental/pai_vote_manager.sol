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
    bool assetIdsetUp;
    
    mapping(address => uint) balanceOf;
    constructor(address _organizationContract) public {
        paiDAO = PAIDAO(_organizationContract);
    }

    function setVoteAssetGlobalId(uint96 _id) public {
        //require(msg.sender == paiDAO);
        require(!assetIdsetUp,"Asset Global Id has already setted.");
        voteAssetGlobalId = _id;
        assetIdsetUp = true;
    }
    /// get the organization contract address
    function getOrganization() public view returns (address) {
        return paiDAO;
    }

    function getVoteAssetGlobalId() public view returns (uint) {
        return voteAssetGlobalId;
    }

    function deposit() public payable {
        require(assetIdsetUp, "vote asset doesn't setted");
        require(msg.assettype == voteAssetGlobalId,"Only PIS can get vote power");
        balanceOf[msg.sender] = add(balanceOf[msg.sender], msg.value);
    }

    function voteTo(address _vote, uint voteId, bool attitude, uint voteNumber) public {
        Vote(_vote).vote(voteId, attitude, voteNumber);
    }
}




