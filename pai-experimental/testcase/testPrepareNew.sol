pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testPI.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_finance.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/tdc.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/settlement.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/fake_btc_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_election.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_PISvote_special.sol";
// import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_PISvote_standard.sol";
// import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_director_vote.sol";


contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO(string _str) public returns (address) {
        return (new FakePaiDao(_str));
    }

    function execute(address target, bytes4 selector, bytes params, uint amount, uint assettype) public returns (bool){
        return target.call.value(amount, assettype)(abi.encodePacked(selector, params));
    }

    function execute(address target, bytes4 selector, bytes params) public returns (bool){
        return target.call(abi.encodePacked(selector, params));
    }

    // function createPAIDAONoGovernance(string _str) public returns (address) {
    //     return (new FakePaiDaoNoGovernance(_str));
    // }

    // function callInit(address paidao) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("init()"));
    //     bool result = PAIDAO(paidao).call(methodId);
    //     return result;
    // }

    function callCreateNewRole(address paidao, string newRole, string superior, uint32 limit) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("createNewRole(bytes,bytes,uint32)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,bytes(newRole),bytes(superior),limit));
        return result;
    }

    function callChangeTopAdmin(address paidao, string newAdmin) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeTopAdmin(string)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,newAdmin));
        return result;
    }

    function callAddMember(address paidao, address _address, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("addMember(address,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,_address,bytes(role)));
        return result;
    }

    function callRemoveMember(address paidao, address _address, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("removeMember(address,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,_address,bytes(role)));
        return result;
    }

    function callMint(address paidao, uint amount, address dest) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("mint(uint256,address)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,amount,dest));
        return result;
    }

    // function callBurn(address paidao, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("burn()"));
    //     bool result = PAIDAO(paidao).call.value(amount,id)(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callResetMembers(address paidao, address[] _members, string role) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("resetMembers(address[],bytes)"));
    //     bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, _members, bytes(role)));
    //     return result;
    // }

    function callChangeSuperior(address paidao, string role, string newSuperior) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeSuperior(bytes,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),bytes(newSuperior)));
        return result;
    }

    // function callChangeMemberLimit(address paidao, string role, uint32 limit) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("changeMemberLimit(bytes,uint32)"));
    //     bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),limit));
    //     return result;
    // }

    // function callUpdatePrice(address oracle, uint newPrice) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updatePrice(uint256)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newPrice));
    //     return result;
    // }

    // function callDisableOne(address oracle, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("disableOne(address)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, addr));
    //     return result;
    // }

    // function callEnableOne(address oracle, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("enableOne(address)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, addr));
    //     return result;
    // }

    // function callModifyDisableOracleLimit(address oracle, uint8 newLimit) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("modifyDisableOracleLimit(uint8)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newLimit));
    //     return result;
    // }

    // function callModifyUpdateInterval(address oracle, uint newInterval) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("modifyUpdateInterval(uint256)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newInterval));
    //     return result;
    // }

    // function callModifySensitivityTime(address oracle, uint newTime) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("modifySensitivityTime(uint256)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newTime));
    //     return result;
    // }

    // function callModifySensitivityRate(address oracle, uint newRate) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("modifySensitivityRate(uint256)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newRate));
    //     return result;
    // }

    // function callEmptyDisabledOracle(address oracle) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("emptyDisabledOracle()"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callUpdateCollateral(address oracle,uint96 newId) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateCollateral(uint96)"));
    //     bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId,newId));
    //     return result;
    // }

    // function callUpdateLendingRate(address setting, uint newRate) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateLendingRate(uint256)"));
    //     bool result = Setting(setting).call(abi.encodeWithSelector(methodId, newRate));
    //     return result;
    // }

    // function callUpdateDepositRate(address setting, uint newRate) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateDepositRate(uint256)"));
    //     bool result = Setting(setting).call(abi.encodeWithSelector(methodId, newRate));
    //     return result;
    // }

    function callUpdateRatioLimit(address setting, uint96 assetGlobalId, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateRatioLimit(uint96,uint256)"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId,assetGlobalId,newRate));
        return result;
    }

    // function callGlobalShutDown(address setting) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("globalShutDown()"));
    //     bool result = Setting(setting).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callGlobalReopen(address setting) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("globalReopen()"));
    //     bool result = Setting(setting).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callSetAssetCollateral(address cdp, address newPriceOracle) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setAssetCollateral(address)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newPriceOracle));
    //     return result;
    // }

    // function callUpdateCutDown(address cdp, uint8 CDPType, uint newRate) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateCutDown(uint8,uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newRate));
    //     return result;
    // }

    // function callUpdateTerm(address cdp, uint8 CDPType, uint newTerm) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateTerm(uint8,uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newTerm));
    //     return result;
    // }

    // function callChangeState(address cdp, uint8 CDPType, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("changeState(uint8,bool)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newState));
    //     return result;
    // }

    // function callSwitchCDPTransfer(address cdp, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchCDPTransfer(bool)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callSwitchCDPCreation(address cdp, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchCDPCreation(bool)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callSwitchLiquidation(address cdp, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchLiquidation(bool)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callSwitchAllCDPFunction(address cdp, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchAllCDPFunction(bool)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callUpdateCreateCollateralRatio(address cdp, uint newRatio, uint newTolerance) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateCreateCollateralRatio(uint256,uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newRatio,newTolerance));
    //     return result;
    // }

    // function callUpdateLiquidationRatio(address cdp, uint newRatio) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateLiquidationRatio(uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newRatio));
    //     return result;
    // }

    // function callUpdateLiquidationPenalty(address cdp, uint newPenalty) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateLiquidationPenalty(uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newPenalty));
    //     return result;
    // }

    // function callUpdateDebtCeiling(address cdp, uint newCeiling) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateDebtCeiling(uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newCeiling));
    //     return result;
    // }

    // function callTransferCDPOwnership(address cdp, uint record, address newOwner, uint _price) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("transferCDPOwnership(uint256,address,uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,record,newOwner,_price));
    //     return result;
    // }

    // function callCreateDepositBorrow(address cdp, uint amount, uint8 _type,uint assetAmount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("createDepositBorrow(uint256,uint8)"));
    //     bool result = TimefliesCDP(cdp).call.value(assetAmount,id)(abi.encodeWithSelector(methodId,amount,_type));
    //     return result;
    // }

    // function callBuyCDP(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("buyCDP(uint256)"));
    //     bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

    // function callTerminate(address cdp) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("terminate()"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callDeposit(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("deposit(uint256)"));
    //     bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

    // function callRepay(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("repay(uint256)"));
    //     bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

    // function callLiquidate(address cdp, uint record) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("liquidate(uint256)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

    // function callSetLiquidator(address cdp, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setLiquidator(address)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,addr));
    //     return result;
    // }

    // function callSetPAIIssuer(address cdp, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setPAIIssuer(address)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,addr));
    //     return result;
    // }

    // function callSetSetting(address cdp, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setSetting(address)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,addr));
    //     return result;
    // }
    
    // function callSetFinance(address cdp, address addr) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setFinance(address)"));
    //     bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,addr));
    //     return result;
    // }



    // function callTerminatePhaseOne(address settlement) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("terminatePhaseOne()"));
    //     bool result = Settlement(settlement).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callTerminatePhaseTwo(address settlement) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("terminatePhaseTwo()"));
    //     bool result = Settlement(settlement).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callSetDiscount1(address liquidator,uint value) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setDiscount1(uint256)"));
    //     bool result = Liquidator(liquidator).call(abi.encodeWithSelector(methodId,value));
    //     return result;
    // }

    // function callSetDiscount2(address liquidator,uint value) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setDiscount2(uint256)"));
    //     bool result = Liquidator(liquidator).call(abi.encodeWithSelector(methodId,value));
    //     return result;
    // }

    // function callAddDebt(address liquidator,uint value) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("addDebt(uint256)"));
    //     bool result = Liquidator(liquidator).call(abi.encodeWithSelector(methodId,value));
    //     return result;
    // }

    // function callBuyCollateral(address liquidator, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("buyCollateral()"));
    //     bool result = Liquidator(liquidator).call.value(amount,id)(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callTDCDeposit(address tdc, uint8 tdcType, uint amount, uint96 id) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("deposit(uint8)"));
    //     bool result = TimefliesTDC(tdc).call.value(amount,id)(abi.encodeWithSelector(methodId,tdcType));
    //     return result;
    // }

    // function callTDCWithdraw(address tdc, uint record, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("withdraw(uint256,uint256)"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,record,amount));
    //     return result;
    // }

    // function callReturnMoney(address tdc, uint record) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("returnMoney(uint256)"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,record));
    //     return result;
    // }

    // function callUpdateBaseInterestRate(address tdc) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateBaseInterestRate()"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callUpdateFloatUp(address tdc, uint8 TDCType, uint newRate) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("updateFloatUp(uint8,uint256)"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,TDCType,newRate));
    //     return result;
    // }

    // function callSwitchDeposit(address tdc, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchDeposit(bool)"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callSwitchGetInterest(address tdc, bool newState) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("switchGetInterest(bool)"));
    //     bool result = TimefliesTDC(tdc).call(abi.encodeWithSelector(methodId,newState));
    //     return result;
    // }

    // function callCashOut(address finance, uint amount, address dest) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("cashOut(uint256,address)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount,dest));
    //     return result;
    // }

    function callSetTDC(address finance, address _tdc) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setTDC(address)"));
        bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,_tdc));
        return result;
    }

    // function callSetAssetPIS(address finance, address newPriceOracle) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setAssetPIS(address)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,newPriceOracle));
    //     return result;
    // }

    // function callPayForInterest(address finance, uint amount, address receiver) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("payForInterest(uint256,address)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount,receiver));
    //     return result;
    // }

    // function callPayForDebt(address finance, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("payForDebt(uint256)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount));
    //     return result;
    // }

    // function callApplyForAirDropCashOut(address finance, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("applyForAirDropCashOut(uint256)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount));
    //     return result;
    // }

    // function callApprovalAirDropCashOut(address finance, uint nonce, bool _result) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("approvalAirDropCashOut(uint256,bool)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,nonce,_result));
    //     return result;
    // }

    // function callOperationCashOut(address finance, uint amount,address dest) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("operationCashOut(uint256,address)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount,dest));
    //     return result;
    // }

    // function callIncreaseOperationCashLimit(address finance, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("increaseOperationCashLimit(uint256)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount));
    //     return result;
    // }

    // function callSetSafePad(address finance, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setSafePad(uint256)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount));
    //     return result;
    // }

    // function callSetPISmintValue(address finance, uint amount) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("setPISmintValue(uint256)"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,amount));
    //     return result;
    // }

    function callSetPISseller(address finance, address newSeller) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setPISseller(address)"));
        bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,newSeller));
        return result;
    }

    // function callMintPIS(address finance) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("mintPIS()"));
    //     bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    // function callGetMoney(address Dividends) public returns (bool) {
    //     bytes4 methodId = bytes4(keccak256("getMoney()"));
    //     bool result = DividendsSample(Dividends).call(abi.encodeWithSelector(methodId));
    //     return result;
    // }

    function callSetCandidatesLimit(address election, bytes role, uint limits) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setCandidatesLimit(bytes,uint256)"));
        bool result = PISelection(election).call(abi.encodeWithSelector(methodId,role,limits));
        return result;
    }

    function callStartProposal(address VSP, uint _startTime,address _targetContract,bytes4 _func,bytes _param,uint amount,uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("startProposal(uint256,address,bytes4,bytes)"));
        bool result = PISVoteSpecial(VSP).call.value(amount,id)(abi.encodeWithSelector(methodId,_startTime,_targetContract,_func,_param));
        return result;
    }

    function callAddNewVoteParam(address VST, uint _passProportion,bytes4 _func,uint _pisVoteDuration) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("addNewVoteParam(uint256,bytes4,uint256)"));
        bool result = PISVoteStandard(VST).call(abi.encodeWithSelector(methodId,_passProportion,_func,_pisVoteDuration));
        return result;
    }
}

contract FakePAIIssuer is PAIIssuer {
    constructor(string _organizationName, address paiMainContract)
        PAIIssuer(_organizationName,paiMainContract)
    public {
        templateName = "Fake-Template-Name-For-Test-pai_issuer";
    }
}

contract FakePaiDao is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-pai_main";
    }
}

contract TestTimeflies {
    uint originalTime;
    uint originalHeight;
    uint testTime;
    uint testHeight;

    constructor() public {
        originalTime = now;
        testTime = now;
        originalHeight = block.number;
        testHeight = block.number;
    }

    function timeNow() public view returns (uint256) {
        return testTime;
    }

    function height() public view returns (uint256) {
        return testHeight;
    }

    function nowBlock() public view returns (uint256) {
        return testHeight;
    }

    function fly(uint age) public {
        if (0 == age) {
            testTime = originalTime;
            testHeight = originalHeight;
            return;
        }
        testTime = testTime + age;
        testHeight = testHeight + uint(age / 5);
    }
}

contract TimefliesOracle is PriceOracle, TestTimeflies {
    constructor(string orcaleGroupName, address paiMainContract, uint _price, uint96 CollateralId)
        PriceOracle(orcaleGroupName, paiMainContract, _price, CollateralId)
        public
    {

    }
}

contract TimefliesCDP is CDP, TestTimeflies {
    constructor(address main, address _issuer, address _oracle, address _liquidator,
        address _setting, address _finance, uint _debtCeiling)
        CDP(main, _issuer, _oracle, _liquidator, _setting, _finance, _debtCeiling)
        public
    {

    }
}

contract TimefliesTDC is TDC, TestTimeflies {
    constructor(address paiMainContract,address _setting,address _issuer,address _finance)
        TDC(paiMainContract,_setting,_issuer, _finance)
        public
    {

    }
}

contract TimefliesFinance is Finance, TestTimeflies {
    constructor(address paiMainContract,address _issuer,address _setting,address _oracle)
        Finance(paiMainContract,_issuer,_setting,_oracle)
        public
    {

    }
}

contract TimefliesElection is PISelection,TestTimeflies {
    constructor(address paiMainContract)
    PISelection(paiMainContract)
    public {
    }
}



contract TimefliesVoteSP is PISVoteSpecial,TestTimeflies {
    constructor(address paiMainContract)
    PISVoteSpecial(paiMainContract)
    public {
    }
}

contract TimefliesVoteST is PISVoteStandard,TestTimeflies {
    constructor(address paiMainContract)
    PISVoteStandard(paiMainContract)
    public {
    }
}

// contract TimefliesVoteDir is DirectorVote,TestTimeflies {
//     constructor(address _organizationContract)
//     DirectorVote(_organizationContract)
//     public {
//     }
// }

