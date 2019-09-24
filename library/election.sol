pragma solidity 0.4.25;

// import "./template.sol";
// import "./array_utils.sol";
// import "./SafeMath.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/array_utils.sol";
import "github.com/evilcc2018/dapp-bin/library/SafeMath.sol";

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

        /// @dev will be recorded in 10**8
        uint nominateQualification;

        /// @dev rates will be recorded in 10**8
        address[] candidates;
        uint[] candidateSupportRates;

        bool created;
        bool sorted;
    }

    /// @dev every election is conducted under a native asset issued on Asimov blockchain
    uint assettype;
    uint totalSupply;

    /// @dev auto incremental index to record all elections
    uint currentElectionIndex = 1;

    mapping (uint=>ElectionRecord) public electionRecords;

    uint constant public ONE_DAY_BLOCKS = 12 * 60 * 24;

    /// @dev before election
    function startElection(uint nominateLength, uint electionLength, uint qualification) internal returns (uint) {
        ElectionRecord storage election = electionRecords[currentElectionIndex];
        require(!election.created);
        election.nominateStartBlock = nowBlock();

        require(nominateLength >= ONE_DAY_BLOCKS);
        require(electionLength >= ONE_DAY_BLOCKS);
        election.electionStartBlock = election.nominateStartBlock.add(nominateLength);
        election.executionStartBlock = election.electionStartBlock.add(electionLength);

        election.nominateQualification = qualification;

        currentElectionIndex = currentElectionIndex.add(1);
        election.created = true;
        
        return currentElectionIndex.sub(1);
    }

    /// @dev nominate stage
    function nominateCandidate(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(percent(msg.value, totalSupply) >= election.nominateQualification);
        require(msg.assettype == assettype);

        require(candidate != 0x0);
        require(!election.candidates.contains(candidate));

        require(nowBlock() >= election.nominateStartBlock);
        require(nowBlock() < election.electionStartBlock);

        election.candidates.push(candidate);
        election.candidateSupportRates.push(0);
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateCandidates(uint electionIndex, address[] candidates) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        uint length = candidates.length;
        require(length > 0);
        require(percent(msg.value, totalSupply) >= election.nominateQualification.mul(length));
        require(msg.assettype == assettype);
        
        for(uint i = 0; i < length; i ++) {
            nominateCandidate(electionIndex, candidates[i]);
        }
        msg.sender.transfer(msg.value,assettype);
    }

    /// @dev election stage
    function nominateCandidatesByAuthroity(uint electionIndex, address[] candidates) internal {
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
            election.candidateSupportRates.push(0);
        }
    }

    function voteForCandidate(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(candidate != 0x0);
        require(election.candidates.contains(candidate));

        require(nowBlock() >= election.electionStartBlock);
        require(nowBlock() < election.executionStartBlock);

        require(msg.assettype == assettype);

        (uint index,) = election.candidates.indexOf(candidate);
        election.candidateSupportRates[index] = election.candidateSupportRates[index].add(percent(msg.value, totalSupply));
    }

    /// @dev execution stage
    function processElectionResult(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(!election.sorted);

        require(nowBlock() >= election.executionStartBlock);
        require(election.candidates.length == election.candidateSupportRates.length);

        if(election.candidates.length > 1) {
            // (election.candidateSupportRates, election.candidates) = bubbleSort(election.candidateSupportRates, election.candidates);
            (election.candidateSupportRates, election.candidates) = quickSort(election.candidateSupportRates, election.candidates, int(0), int(election.candidates.length - 1));
        }

        election.sorted = true;
    }

    /// @dev helper functions
    function nowBlock() public view returns(uint) {
        return block.number;
    }

    /// @dev percent in 10**27
    function percent(uint own, uint total) public pure returns (uint){
        return own.mul(10**27).div(total);
    }

    /// @dev should test gas comsumptions
    function bubbleSort(uint[] memory values, address[] memory addresses) internal returns (uint[], address[]){
        uint length = values.length;
        for (uint i = 0; i < length - 1; i ++) {
            for (uint j = 0; j < length - i - 1; j ++) {
                if(values[j] < values[j+1]) {
                    (values[j], values[j+1]) = (values[j+1], values[j]);
                    (addresses[j], addresses[j+1]) = (addresses[j+1], addresses[j]);
                }
            }
        }
        return (values, addresses);
    }

    /// @dev https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
    function quickSort(uint[] memory values, address[] memory addresses, int left, int right) internal returns (uint[], address[]){
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = values[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (values[uint(i)] > pivot) i++;
            while (pivot > values[uint(j)]) j--;
            if (i <= j) {
                (values[uint(i)], values[uint(j)]) = (values[uint(j)], values[uint(i)]);
                (addresses[uint(i)], addresses[uint(j)]) = (addresses[uint(j)], addresses[uint(i)]);                
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(values, addresses, left, j);
        if (i < right)
            quickSort(values, addresses, i, right);
        
        return (values, addresses);
    }

    /// @dev readonly functions
    function getElectionRecord(uint index) public view returns (uint, uint, uint) {
        return (assettype, totalSupply, electionRecords[index].nominateQualification);
    }

    function getElectionCandidates(uint index) public view returns (address[]) {
        return electionRecords[index].candidates;
    }

    function getElectionCandidateSupportRates(uint index) public view returns (uint[]) {
        return electionRecords[index].candidateSupportRates;
    }
}