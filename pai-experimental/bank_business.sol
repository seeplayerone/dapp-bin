pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/library/acl_slave.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/bank_issuer.sol";


contract BankBusiness is Template, DSMath, ACLSlave {
    mapping(uint32 => AssetParam) params;
    struct AssetParam {
        uint dailyCashInLimit;
        uint singleCashInLimit;
        uint singleCashOutLimit;
        uint cashInRate;
        uint cashOutRate;
        mapping(address => uint) remainingLimit;
        mapping(address => uint) lastUpdateTime; //in blockheight
        bool exist;
        bool enable;
    }

    struct CashOutVote {
        address to;
        uint32 assetIndex;
        uint amount;
        uint agreeVote;
        mapping(address => bool) voted;
        bool excuted;
    }

    uint public totalVoteId = 0;
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
        uint32 assetId,
        uint _dailyCashInLimit,
        uint _singleCashInLimit,
        uint _singleCashOutLimit,
        uint _cashInRate,
        uint _cashOutRate
    ) public auth("DirectorVote@Bank") {
        require(!params[assetId].exist);
        params[assetId].dailyCashInLimit = _dailyCashInLimit;
        params[assetId].singleCashInLimit = _singleCashInLimit;
        params[assetId].singleCashOutLimit = _singleCashOutLimit;
        params[assetId].cashInRate = _cashInRate;
        params[assetId].cashOutRate = _cashOutRate;
        params[assetId].exist = true;
        params[assetId].enable = true;
    }

    function setDailyCashInLimit(uint32 assetId, uint _dailyCashInLimit) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].dailyCashInLimit = _dailyCashInLimit;
    }

    function setSingleCashInLimit(uint32 assetId, uint _singleCashInLimit) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].singleCashInLimit = _singleCashInLimit;
    }

    function setSingleCashOutLimit(uint32 assetId, uint _singleCashOutLimit) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].singleCashOutLimit = _singleCashOutLimit;
    }

    function setCashInRate(uint32 assetId, uint _cashInRate) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].cashInRate = _cashInRate;
    }

    function setCashOutRate(uint32 assetId, uint _cashOutRate) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].cashOutRate = _cashOutRate;
    }

    function switchAssetBusiness(uint32 assetId, bool newState) public auth("DirectorVote@Bank") {
        require(params[assetId].exist);
        params[assetId].enable = newState;
    }

    function switchAllBusiness(bool newState) public auth("DirectorVote@Bank") {
        disableAll = newState;
    }

    
    function deposit(string txid, string depAddr, address to, uint32 assetIndex, uint amount)
    public auth("Minter@Bank")
    {
        require(bytes(txid).length > 0, "requires txid");
        require(bytes(depAddr).length > 0, "requires depAddr");
        require(amount > 0,"amount must greater than zero");
        require(params[assetIndex].enable);
        require(!disableAll);
        if(params[assetIndex].singleCashInLimit < amount) {
            cashOutVote(to, assetIndex, amount);
            return;
        }
        if(crossADay(params[assetIndex].lastUpdateTime[msg.sender])) {
            if(params[assetIndex].dailyCashInLimit < amount) {
                cashOutVote(to, assetIndex, amount);
                return;
            }
        } else {
            if(params[assetIndex].remainingLimit[msg.sender] < amount) {
                cashOutVote(to, assetIndex, amount);
                return;
            }
        }
        params[assetIndex].lastUpdateTime[msg.sender] = height();
        if(crossADay(params[assetIndex].lastUpdateTime[msg.sender])) {
            params[assetIndex].remainingLimit[msg.sender] = sub(params[assetIndex].dailyCashInLimit,amount);
        } else {
            params[assetIndex].remainingLimit[msg.sender] = sub(params[assetIndex].remainingLimit[msg.sender],amount);
        }
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

    function cashOutVote(address _to, uint32 _assetIndex, uint _amount) internal {
        require(_amount > 0, "amount must greater than zero");
        totalVoteId = add(totalVoteId,1);
        cashOutVotes[totalVoteId].to = _to;
        cashOutVotes[totalVoteId].assetIndex = _assetIndex;
        cashOutVotes[totalVoteId].amount = _amount;
    }

    function vote(uint voteid) public auth("Director@Bank") {
        require(cashOutVotes[voteid].amount != 0,"vote not exist");
        require(!cashOutVotes[voteid].excuted,"vote excuted");
        require(!cashOutVotes[voteid].voted[msg.sender],"you already voted");
        cashOutVotes[voteid].agreeVote = add(cashOutVotes[voteid].agreeVote,1);
        cashOutVotes[voteid].voted[msg.sender] = true;
        if(cashOutVotes[voteid].agreeVote >= rmul(master.getMemberLimit(bytes(DIRECTOR)),passRate)) {
            cashOutVotes[voteid].excuted = true;
            emit MintAsset(cashOutVotes[voteid].assetIndex);
            uint tax = rmul(params[cashOutVotes[voteid].assetIndex].cashInRate,cashOutVotes[voteid].amount);
            if(tax > 0) {
                issuer.mint(cashOutVotes[voteid].assetIndex, tax, finance);
                emit TransferAsset(finance, tax);
            }
            uint rest = sub(cashOutVotes[voteid].amount,tax);
            issuer.mint(cashOutVotes[voteid].assetIndex, rest, cashOutVotes[voteid].to);
            emit TransferAsset(cashOutVotes[voteid].to, rest);
        }
    }

    /**
     * @dev burn asset
     *
     * @param recAddr receive address
     */
    function withdraw(string recAddr,uint32 assetIndex)
    public payable
    {
        require(params[assetIndex].enable);
        require(!disableAll);
        require(bytes(recAddr).length > 0, "requires recAddr");
        require(params[assetIndex].singleCashOutLimit >= msg.value, "Too much money in one cash-out apply");
        uint tax = rmul(params[assetIndex].cashOutRate,msg.value);
        if(tax > 0) {
            finance.transfer(tax,msg.assettype);
            emit TransferAsset(finance, tax);
        }
        uint rest = sub(msg.value,tax);
        issuer.burn.value(msg.assettype,rest)(assetIndex);
        emit BurnAsset(msg.assettype, msg.value);
    }
}