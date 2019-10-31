pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "../library/template.sol";
import "../library/utils/ds_math.sol";

contract ProposalData is DSMath, Template {
    struct Proposal {
        bytes32 attachmentHash; //to commit the proposal attachment
        ProposalItem[] items;
    }

    struct ProposalItem {
        address target; /// call contract of vote result
        bytes4 func; /// functionHash of the callback function
        bytes param; /// parameters for the callback function
    }

    mapping(uint => Proposal) public proposals;
    uint public lastProposalId = 0;

    /// @dev create a new proposal
    function newProposal(bytes32 _attachmentHash, ProposalItem[] memory _items) public returns(uint) {
        lastProposalId = add(lastProposalId,1);
        proposals[lastProposalId].attachmentHash = _attachmentHash;
        uint len = _items.length;
        for(uint i = 0; i < len; i++) {
            proposals[lastProposalId].items.push(_items[i]);
        }
        return lastProposalId;
    }

    function getProposalItems(uint proposalId) public view returns(ProposalItem[]) {
        return proposals[proposalId].items;
    }
}