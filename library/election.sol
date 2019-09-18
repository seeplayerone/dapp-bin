pragma solidity 0.4.25;

// import "./template.sol";
// import "./array_utils.sol";
// import "./SafeMath.sol";

import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/library/array_utils.sol";
import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";

interface Issuer {
    function getAssetType() public view returns (uint);
    function getAssetInfo(uint32 index) public view returns (bool, string, string, string, uint32, uint);
}

contract Election is Template {

    using AddressArrayUtils for address[];
    using SafeMath for uint256;

    struct ElectionRecord {
        /// @dev there are three stages in an election
        ///       nominate stage ~ a qulified address starts an election, all quilified addresses nominate candidates
        ///       election stage ~ all stake holders vote for their heros
        ///       execution stage ~ election starter triggers the contract to process the election result 
        uint nominateStartBlock;
        uint electionStartBlock;
        uint executionStartBlock;

        /// @dev every election is conducted under a native asset issued on Asimov blockchain
        uint assettype;
        uint totalSupply;
        /// @dev will be recorded in 10**8
        uint nominateQualification;

        /// @dev rates will be recorded in 10**8
        address[] candidates;
        uint[] candidateSupportRates;

        bool created;
        bool sorted;
    }

    /// @dev auto incremental index to record all elections
    uint currentElectionIndex = 1;

    mapping (uint=>ElectionRecord) public electionRecords;

    uint constant public ONE_DAY_BLOCKS = 12 * 60 * 24;

    /// @dev before election
    function startElection(uint nominateLength, uint electionLength, address issuerAddress, uint qualification) public returns (uint) {
        ElectionRecord storage election = electionRecords[currentElectionIndex];
        require(!election.created);
        election.nominateStartBlock = block.number;

        require(nominateLength >= ONE_DAY_BLOCKS);
        require(electionLength >= ONE_DAY_BLOCKS);
        election.electionStartBlock = election.nominateStartBlock.add(nominateLength);
        election.executionStartBlock = election.electionStartBlock.add(electionLength);

        election.nominateQualification = qualification;

        require(issuerAddress != 0x0);
        election.assettype = Issuer(issuerAddress).getAssetType();
        (, , , , , election.totalSupply) = Issuer(issuerAddress).getAssetInfo(1);

        currentElectionIndex = currentElectionIndex.add(1);
        election.created = true;
        
        return currentElectionIndex.sub(1);
    } 

    /// @dev nominate stage
    function nominateCandidate(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(percent(msg.value, election.totalSupply) >= election.nominateQualification);
        require(msg.assettype == election.assettype);

        require(candidate != 0x0);
        require(!election.candidates.contains(candidate));

        require(nowBlock() >= election.nominateStartBlock);
        require(nowBlock() < election.electionStartBlock);

        election.candidates.push(candidate);
        election.candidateSupportRates.push(0);
    } 

    function nominateCandidates(uint electionIndex, address[] candidates) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        uint length = candidates.length;
        require(length > 0);
        require(percent(msg.value, election.totalSupply) >= election.nominateQualification.mul(length));
        require(msg.assettype == election.assettype);
        
        for(uint i = 0; i < length; i ++) {
            nominateCandidate(electionIndex, candidates[i]);
        }
    }

    /// @dev election stage
    function nominateCandidatesByAuthroity(uint electionIndex, address[] candidates) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(nowBlock() >= election.electionStartBlock);
        require(nowBlock() < election.executionStartBlock);

        uint length = candidates.length;
        require(length > 0);

        for(uint i = 0; i < length; i ++) {
            address candidate = candidates[i];
            require(candidate != 0x0);
            require(!election.candidates.contains(candidate));

            election.candidates.push(candidate);
        }
    }

    function voteForCandidate(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(candidate != 0x0);
        require(election.candidates.contains(candidate));

        require(nowBlock() >= election.electionStartBlock);
        require(nowBlock() < election.executionStartBlock);

        require(msg.assettype == election.assettype);

        (uint index,) = election.candidates.indexOf(candidate);
        election.candidateSupportRates[index] = election.candidateSupportRates[index].add(percent(msg.value, election.totalSupply));
    }

    /// @dev execution stage
    function processElectionResult(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(!election.sorted);

        require(nowBlock() >= election.executionStartBlock);
        require(election.candidates.length == election.candidateSupportRates.length);

        if(election.candidates.length > 1) {
            quicksort(election.candidateSupportRates, election.candidates, 0, election.candidates.length - 1);
        }

        election.sorted = true;
    }

    /// @dev readonly and helper functions
    function nowBlock() public view returns(uint) {
        return block.number;
    }

    /// @dev percent in 10**8
    function percent(uint own, uint total) public pure returns (uint){
        return own.mul(10**8).div(total);
    } 

    function quicksort(uint[] storage values, address[] storage addresses, uint left, uint right) internal {
        uint i = left;
        uint j = right;
        uint pivot = values[left + (right - left) / 2];
        while (i <= j) {
            while (values[i] < pivot) i++;
            while (pivot < values[j]) j--;
            if (i <= j) {
                (values[i], values[j]) = (values[j], values[i]);
                (addresses[i], addresses[j]) = (addresses[j], addresses[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            quicksort(values, addresses, left, j);
        if (i < right)
            quicksort(values, addresses, i, right);
    }

    /// @dev readonly functions
    function getElectionRecord(uint index) returns (uint, uint, uint) {
        return (electionRecords[index].assettype, electionRecords[index].totalSupply, electionRecords[index].nominateQualification);
    }

    function getElectionCandidates(uint index) returns (address[]) {
        return electionRecords[index].candidates;
    }

    function getElectionCandidateSupportRates(uint index) returns (uint[]) {
        return electionRecords[index].candidateSupportRates;
    }
}