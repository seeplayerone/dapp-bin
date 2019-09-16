pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_main.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_issuer.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_setting.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_finance.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";

contract FakePerson is Template {
    function() public payable {}

    function createPAIDAO(string _str) public returns (address) {
        return (new FakePaiDao(_str));
    }

    function createPAIDAONoGovernance(string _str) public returns (address) {
        return (new FakePaiDaoNoGovernance(_str));
    }

    function callInit(address paidao) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("init()"));
        bool result = PAIDAO(paidao).call(methodId);
        return result;
    }

    function callCreateNewRole(address paidao, string newRole, string superior, uint32 limit) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("createNewRole(bytes,bytes,uint32)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId,bytes(newRole),bytes(superior),limit));
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

    function callBurn(address paidao, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("burn()"));
        bool result = PAIDAO(paidao).call.value(amount,id)(abi.encodeWithSelector(methodId));
        return result;
    }

    function callResetMembers(address paidao, address[] _members, string role) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("resetMembers(address[],bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, _members, bytes(role)));
        return result;
    }

    function callChangeSuperior(address paidao, string role, string newSuperior) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeSuperior(bytes,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),bytes(newSuperior)));
        return result;
    }

    function callChangeMemberLimit(address paidao, string role, uint32 limit) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeMemberLimit(bytes,uint32)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),limit));
        return result;
    }

    function callUpdatePrice(address oracle, uint newPrice) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updatePrice(uint256)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newPrice));
        return result;
    }

    function callDisableOne(address oracle, address addr) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("disableOne(address)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, addr));
        return result;
    }

    function callEnableOne(address oracle, address addr) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("enableOne(address)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, addr));
        return result;
    }

    function callModifyDisableOracleLimit(address oracle, uint8 newLimit) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("modifyDisableOracleLimit(uint8)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newLimit));
        return result;
    }

    function callModifyUpdateInterval(address oracle, uint newInterval) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("modifyUpdateInterval(uint256)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newInterval));
        return result;
    }

    function callModifySensitivityTime(address oracle, uint newTime) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("modifySensitivityTime(uint256)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newTime));
        return result;
    }

    function callModifySensitivityRate(address oracle, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("modifySensitivityRate(uint256)"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId, newRate));
        return result;
    }

    function callEmptyDisabledOracle(address oracle) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("emptyDisabledOracle()"));
        bool result = PriceOracle(oracle).call(abi.encodeWithSelector(methodId));
        return result;
    }

    function callUpdateLendingRate(address setting, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateLendingRate(uint256)"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId, newRate));
        return result;
    }

    function callUpdateDepositRate(address setting, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateDepositRate(uint256)"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId, newRate));
        return result;
    }

    function callUpdateRatioLimit(address setting, uint96 assetGlobalId, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateRatioLimit(uint96,uint256)"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId,assetGlobalId,newRate));
        return result;
    }

    function callGlobalShutDown(address setting) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("globalShutDown()"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId));
        return result;
    }

    function callGlobalReopen(address setting) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("globalReopen()"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId));
        return result;
    }

    function callSetAssetCollateral(address cdp, uint96 assetType, address newPriceOracle) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setAssetCollateral(uint96,address)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,assetType,newPriceOracle));
        return result;
    }

    function callUpdateCutDown(address cdp, uint8 CDPType, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateCutDown(uint8,uint256)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newRate));
        return result;
    }

    function callUpdateTerm(address cdp, uint8 CDPType, uint newTerm) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateTerm(uint8,uint256)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newTerm));
        return result;
    }

    function callChangeState(address cdp, uint8 CDPType, bool newState) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeState(uint8,bool)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,CDPType,newState));
        return result;
    }

    function callSwitchCDPTransfer(address cdp, bool newState) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("switchCDPTransfer(bool)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
        return result;
    }

    function callSwitchCDPCreation(address cdp, bool newState) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("switchCDPCreation(bool)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
        return result;
    }

    function callSwitchLiquidation(address cdp, bool newState) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("switchLiquidation(bool)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
        return result;
    }

    function callSwitchAllCDPFunction(address cdp, bool newState) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("switchAllCDPFunction(bool)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newState));
        return result;
    }

    function callUpdateCreateCollateralRatio(address cdp, uint newRatio, uint newTolerance) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateCreateCollateralRatio(uint256,uint256)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newRatio,newTolerance));
        return result;
    }

    function callUpdateLiquidationRatio(address cdp, uint newRatio) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateLiquidationRatio(uint256)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newRatio));
        return result;
    }

    function callUpdateDebtCeiling(address cdp, uint newCeiling) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateDebtCeiling(uint256)"));
        bool result = TimefliesCDP(cdp).call(abi.encodeWithSelector(methodId,newCeiling));
        return result;
    }

    function callBuyCDP(address cdp, uint record, uint amount, uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("buyCDP(uint256)"));
        bool result = TimefliesCDP(cdp).call.value(amount,id)(abi.encodeWithSelector(methodId,record));
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

contract FakePaiDaoNoGovernance is PAIDAO {
    constructor(string _organizationName)
        PAIDAO(_organizationName)
        public
    {
        templateName = "Fake-Template-Name-For-Test-pai_main2";
    }

    function canPerform(string role, address _addr) public view returns (bool) {
        return true;
    }

    function canPerform(bytes role, address _addr) public view returns (bool) {
        return true;
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
    constructor(string orcaleGroupName, address paiMainContract, uint _price)
        PriceOracle(orcaleGroupName, paiMainContract, _price)
        public
    {

    }
}

contract TimefliesCDP is CDP, TestTimeflies {
    constructor(address main, address _issuer, address _oracle, address _liquidator,
        address _setting, address _finance, uint96 collateralGlobalId, uint _debtCeiling)
        CDP(main, _issuer, _oracle, _liquidator, _setting, _finance, collateralGlobalId, _debtCeiling)
        public
    {

    }
}