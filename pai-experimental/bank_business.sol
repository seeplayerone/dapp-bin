pragma solidity 0.4.25;

import "../library/template.sol";
import "../library/acl_slave.sol";
import "./bank_issuer.sol";


contract BankBusiness is Template, DSMath, ACLSlave {
    mapping(uint32 => AssetParam) public params;
    struct AssetParam {
        uint minterDailyCashInLimit;
        uint minterSingleCashInLimit;
        uint userSingleCashOutUpperLimit;
        uint userSingleCashOutLowerLimit;
        uint allUserDailyCashOutLimit;
        uint cashInRate;
        uint cashOutRate;
        mapping(address => uint) remainingLimit;
        mapping(address => uint) lastUpdateTime; //in blockheight
        uint remainingCashOutLimit;
        uint lastCashOutTime;
        bool exist;
        bool enable;
    }

    struct CashOutVote {
        address to;
        uint32 assetIndex;
        uint amount;
        uint agreeVote;
        uint startTime;
        mapping(address => bool) voted;
        bool excuted;
    }
    uint public duration = 3 days / 5;

    uint public totalVoteId = 0;
    uint32 public currentAssetId = 0;
    uint passRate = RAY / 2;
    mapping(uint => CashOutVote) cashOutVotes;
    uint baseTime;
    bool public disableAll;
    uint constant ONE_DAY_BLOCK = 17280;
    BankIssuer public issuer;
    address public finance;
    string DIRECTOR = "Director@Bank";

    /// mint asset
    event MintAsset(uint);
    /// transfer asset
    event TransferAsset(address, uint);
    /// burn asset
    event BurnAsset(uint, uint);
    
    constructor(address paiMainContract, address _issuer, address _finance, uint _baseTime) public
    {
        master = ACLMaster(paiMainContract);
        issuer = BankIssuer(_issuer);
        finance = _finance;
        if(0 == _baseTime) {
            baseTime = block.number;
        } else {
            baseTime = _baseTime;
        }
    }

    function height() public view returns (uint256) {
        return block.number;
    }

    function crossADay(uint lastUpdateTime) public view returns(bool) {
        if(0 == lastUpdateTime) {
            return true;
        }
        uint a = sub(lastUpdateTime,baseTime) / ONE_DAY_BLOCK;
        uint b = sub(height(),baseTime) / ONE_DAY_BLOCK;
        return(a != b);
    }

    function createNewAsset(
        uint _dailyCashInLimit,
        uint _singleCashInLimit,
        uint _singleCashOutUpperLimit,
        uint _singleCashOutLowerLimit,
        uint _allUserDailyCashOutLimit,
        uint _cashInRate,
        uint _cashOutRate,
        string name,
        string symbol,
        string description
    ) public auth("50%DirVote@Bank") {
        require(currentAssetId != uint32(-1));
        currentAssetId = currentAssetId + 1 ;
        params[currentAssetId].minterDailyCashInLimit = _dailyCashInLimit;
        params[currentAssetId].minterSingleCashInLimit = _singleCashInLimit;
        params[currentAssetId].userSingleCashOutUpperLimit = _singleCashOutUpperLimit;
        params[currentAssetId].userSingleCashOutLowerLimit = _singleCashOutLowerLimit;
        params[currentAssetId].allUserDailyCashOutLimit = _allUserDailyCashOutLimit;
        params[currentAssetId].remainingCashOutLimit = _allUserDailyCashOutLimit;
        params[currentAssetId].cashInRate = _cashInRate;
        params[currentAssetId].cashOutRate = _cashOutRate;
        params[currentAssetId].exist = true;
        params[currentAssetId].enable = true;
        issuer.createAsset(name,symbol,description,currentAssetId);
    }

    function setDailyCashInLimit(uint32 assetId, uint _dailyCashInLimit) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].minterDailyCashInLimit = _dailyCashInLimit;
    }

    function setSingleCashInLimit(uint32 assetId, uint _singleCashInLimit) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].minterSingleCashInLimit = _singleCashInLimit;
    }

    function setSingleCashOutUpperLimit(uint32 assetId, uint _singleCashOutLimit) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].userSingleCashOutUpperLimit = _singleCashOutLimit;
    }

    function setSingleCashOutLowerLimit(uint32 assetId, uint _dailyCashOutLimit) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].userSingleCashOutLowerLimit = _dailyCashOutLimit;
    }

    function setDailyCashOutLimit(uint32 assetId, uint _singleCashOutLimit) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].allUserDailyCashOutLimit = _singleCashOutLimit;
    }

    function setCashInRate(uint32 assetId, uint _cashInRate) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].cashInRate = _cashInRate;
    }

    function setCashOutRate(uint32 assetId, uint _cashOutRate) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].cashOutRate = _cashOutRate;
    }

    function switchAssetBusiness(uint32 assetId, bool newState) public auth("50%DirVote@Bank") {
        require(params[assetId].exist);
        params[assetId].enable = newState;
    }

    function switchAllBusiness(bool newState) public auth("100%DirVote@Bank") {
        disableAll = newState;
    }

    
    function deposit(string txid, string depAddr, address to, uint32 assetIndex, uint amount) public auth("Minter@Bank"){
        require(bytes(txid).length > 0, "requires txid");
        require(bytes(depAddr).length > 0, "requires depAddr");
        require(amount > 0,"amount must greater than zero");
        require(params[assetIndex].enable);
        require(!disableAll);
        require(params[assetIndex].minterSingleCashInLimit >= amount);
        if(crossADay(params[assetIndex].lastUpdateTime[msg.sender])) {
            params[assetIndex].remainingLimit[msg.sender] = sub(params[assetIndex].minterDailyCashInLimit,amount);
        } else {
            params[assetIndex].remainingLimit[msg.sender] = sub(params[assetIndex].remainingLimit[msg.sender],amount);
        }
        params[assetIndex].lastUpdateTime[msg.sender] = height();
        mintInternal(to,assetIndex,amount);
    }

    function mintInternal(address to, uint32 assetIndex, uint amount) internal {
        emit MintAsset(assetIndex);
        uint tax = rmul(params[assetIndex].cashInRate,amount);
        if(tax > 0) {
            issuer.mint(assetIndex, tax, finance);
            emit TransferAsset(finance, tax);
        }
        uint rest = sub(amount,tax);
            issuer.mint(assetIndex, rest, to);
        emit TransferAsset(to, rest);

    }

    function startCashOutVote(address _to, uint32 _assetIndex, uint _amount) public auth("Minter@Bank") {
        require(_amount > 0, "amount must greater than zero");
        totalVoteId = add(totalVoteId,1);
        cashOutVotes[totalVoteId].to = _to;
        cashOutVotes[totalVoteId].assetIndex = _assetIndex;
        cashOutVotes[totalVoteId].amount = _amount;
        cashOutVotes[totalVoteId].startTime = height();
    }

    function vote(uint voteid) public auth("Director@Bank") {
        require(cashOutVotes[voteid].amount != 0,"vote not exist");
        require(!cashOutVotes[voteid].excuted,"vote excuted");
        require(!cashOutVotes[voteid].voted[msg.sender],"you already voted");
        require(height() < add(cashOutVotes[voteid].startTime,duration));
        cashOutVotes[voteid].agreeVote = add(cashOutVotes[voteid].agreeVote,1);
        cashOutVotes[voteid].voted[msg.sender] = true;
        if(cashOutVotes[voteid].agreeVote >= rmul(master.getMemberLimit(bytes(DIRECTOR)),passRate)) {
            cashOutVotes[voteid].excuted = true;
            mintInternal(cashOutVotes[voteid].to,cashOutVotes[voteid].assetIndex,cashOutVotes[voteid].amount);
        }
    }

    /**
     * @dev burn asset
     *
     * @param recAddr receive address
     */
    function withdraw(string recAddr)
    public payable
    {
        uint32 assetIndex = uint32(msg.assettype);
        require(params[assetIndex].enable);
        require(!disableAll);
        require(bytes(recAddr).length > 0, "requires recAddr");
        require(params[assetIndex].userSingleCashOutUpperLimit >= msg.value, "Too much money in one cash-out apply");
        require(params[assetIndex].userSingleCashOutLowerLimit <= msg.value, "Too little money in one cash-out apply");
        if(crossADay(params[assetIndex].lastCashOutTime)) {
            //require is already include in sub()        
            params[assetIndex].remainingCashOutLimit = sub(params[assetIndex].allUserDailyCashOutLimit,msg.value);
        } else {
            //require is already include in sub()
            params[assetIndex].remainingCashOutLimit = sub(params[assetIndex].remainingCashOutLimit,msg.value);
        }
        params[assetIndex].lastCashOutTime = height();
        uint tax = rmul(params[assetIndex].cashOutRate,msg.value);
        if(tax > 0) {
            finance.transfer(tax,msg.assettype);
            emit TransferAsset(finance, tax);
        }
        uint rest = sub(msg.value,tax);
        issuer.burn.value(rest,msg.assettype)();
        emit BurnAsset(msg.assettype, msg.value);
    }
}