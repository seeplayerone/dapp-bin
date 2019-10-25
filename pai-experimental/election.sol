pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/utils/array_utils.sol";
import "../library/utils/safe_math.sol";

contract Election is Template {

    using AddressArrayUtils for address[];
    using SafeMath for uint256;

    struct ElectionRecord {
        /// @dev there are 4 stages in an election
        ///       nominate stage ~ a qualified role starts an election, all quilified addresses nominate candidates
        ///       election stage ~ all stake holders vote for their heros
        ///       execution stage ~ election starter (or anyone) triggers the contract to process the election result
        ///       cease stage ~ election starter (or anyone) triggers to cease the election if the result is not process after certain period
        uint nominationStartBlock;
        uint electionStartBlock;
        uint executionStartBlock;
        uint ceaseStartBlock;

        /// @dev nomination qualification, recorded in 10**8
        uint qualification;
    
        /// @dev total supply may change so it need to be specified in every election
        uint totalSupply;

        /// @dev candidates and their supporting rates, recorded in 10**8
        address[] candidates;
        uint[] candidateSupportRates;

        bool created;
        bool processed;
        bool ceased;
    }

    /// role to elect
    bytes role;

    /// @dev native asset on Asimov blockchain used to nominate and vote
    uint assettype;

    /// @dev auto incremental index to record all elections
    uint public currentIndex = 0;

    mapping (uint=>ElectionRecord) public electionRecords;

    uint constant public ONE_DAY_BLOCKS = 12 * 60 * 24;

    /// @dev before election
    function startElection(uint nominationLength, uint electionLength, uint executionLength, uint qualification, uint totalSupply) internal returns (uint) {
        /// only one active election per contract - designed for safety considerations
        if(currentIndex > 0) {
            require(electionFinished(currentIndex));
        }

        currentIndex = currentIndex.add(1);

        ElectionRecord storage election = electionRecords[currentIndex];
        require(!election.created);
        require(nominationLength >= ONE_DAY_BLOCKS);
        require(electionLength >= ONE_DAY_BLOCKS);

        election.nominationStartBlock = nowBlock();
        election.electionStartBlock = election.nominationStartBlock.add(nominationLength);
        election.executionStartBlock = election.electionStartBlock.add(electionLength);
        election.ceaseStartBlock = election.executionStartBlock.add(executionLength);

        election.qualification = qualification;
        election.totalSupply = totalSupply;

        election.created = true;
        
        return currentIndex;
    }

    function electionFinished(uint electionIndex) internal view returns (bool) {
        ElectionRecord storage election = electionRecords[electionIndex];
        return election.processed || election.ceased;
    }

    function nominateCandidateByAssetInternal(uint electionIndex, address candidate) internal {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(percent(msg.value, election.totalSupply) >= election.qualification);
        require(msg.assettype == assettype);

        require(candidate != 0x0);
        require(!election.candidates.contains(candidate));

        require(nowBlock() >= election.nominationStartBlock);
        require(nowBlock() < election.electionStartBlock);

        election.candidates.push(candidate);
        election.candidateSupportRates.push(0);
    }

    /// @dev nominate stage
    function nominateCandidateByAsset(uint electionIndex, address candidate) public payable {
        nominateCandidateByAssetInternal(electionIndex, candidate);
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateCandidatesByAsset(uint electionIndex, address[] candidates) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        uint length = candidates.length;
        require(length > 0);
        require(percent(msg.value, election.totalSupply) >= election.qualification.mul(length));
        require(msg.assettype == assettype);
        
        for(uint i = 0; i < length; i ++) {
            nominateCandidateByAssetInternal(electionIndex, candidates[i]);
        }
        msg.sender.transfer(msg.value,assettype);
    }

    function nominateCandidatesByAuthority(uint electionIndex, address[] candidates) internal {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(nowBlock() >= election.nominationStartBlock);
        require(nowBlock() < election.electionStartBlock);

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

    function cancelNomination(uint electionIndex) public {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(nowBlock() >= election.nominationStartBlock);
        require(nowBlock() < election.electionStartBlock);

        uint len = election.candidates.length;
        for(uint i = 0; i < len; i ++) {
            if(election.candidates[i] == msg.sender) {
                if(i != len - 1) {
                    election.candidates[i] = election.candidates[len-1];
                    election.candidateSupportRates[i] = election.candidateSupportRates[len-1];
                }
                election.candidates.length--;
                election.candidateSupportRates.length--;
                break;
            }
        }
    }

    /// @dev election stage
    function voteForCandidate(uint electionIndex, address candidate) public payable {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);

        require(candidate != 0x0);
        require(election.candidates.contains(candidate));

        require(nowBlock() >= election.electionStartBlock);
        require(nowBlock() < election.executionStartBlock);

        require(msg.assettype == assettype);

        (uint index,) = election.candidates.indexOf(candidate);
        election.candidateSupportRates[index] = election.candidateSupportRates[index].add(percent(msg.value, election.totalSupply));
    }

    /// @dev execution stage
    function processElectionResult(uint electionIndex) internal {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(!election.processed);
        require(!election.ceased);

        require(nowBlock() >= election.executionStartBlock);
        require(election.candidates.length == election.candidateSupportRates.length);

        if(election.candidates.length > 1) {
            // (election.candidateSupportRates, election.candidates) = bubbleSort(election.candidateSupportRates, election.candidates);
            (election.candidateSupportRates, election.candidates) = quickSort(election.candidateSupportRates, election.candidates, int(0), int(election.candidates.length - 1));
        }

        election.processed = true;
    }

    function ceaseElection(uint electionIndex) internal {
        ElectionRecord storage election = electionRecords[electionIndex];
        require(election.created);
        require(!election.processed);
        require(nowBlock() >= election.ceaseStartBlock);
        election.ceased = true;
    }

    /// @dev helper functions
    function nowBlock() public view returns(uint) {
        return block.number;
    }

    /// @dev percent in 10**8
    function percent(uint own, uint total) public pure returns (uint){
        return own.mul(10**27).div(total);
    }

    /// @dev should test gas comsumptions
    // function bubbleSort(uint[] memory values, address[] memory addresses) internal returns (uint[], address[]){
    //     uint length = values.length;
    //     for (uint i = 0; i < length - 1; i ++) {
    //         for (uint j = 0; j < length - i - 1; j ++) {
    //             if(values[j] < values[j+1]) {
    //                 (values[j], values[j+1]) = (values[j+1], values[j]);
    //                 (addresses[j], addresses[j+1]) = (addresses[j+1], addresses[j]);
    //             }
    //         }
    //     }
    //     return (values, addresses);
    // }

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
        return (assettype, electionRecords[index].totalSupply, electionRecords[index].qualification);
    }

    function getElectionCandidates(uint index) public view returns (address[]) {
        return electionRecords[index].candidates;
    }

    function getElectionCandidateSupportRates(uint index) public view returns (uint[]) {
        return electionRecords[index].candidateSupportRates;
    }

    function getNoneZeroElectionCandidates(uint index) public view returns (address[]) {
        address[] memory results;
        uint idx = 0;
        for(uint i = 0; i < electionRecords[index].candidateSupportRates.length; i++) {
            if (0 == electionRecords[index].candidateSupportRates[i]) {
                return results;
            }
            results[idx] = electionRecords[index].candidates[i];
            idx = idx + 1;
        }
        return results;
    }
}