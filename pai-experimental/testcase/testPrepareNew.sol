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
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_PISvote_standard.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/pai_director_vote.sol";


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

    function callChangeSuperior(address paidao, string role, string newSuperior) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("changeSuperior(bytes,bytes)"));
        bool result = PAIDAO(paidao).call(abi.encodeWithSelector(methodId, bytes(role),bytes(newSuperior)));
        return result;
    }

    function callUpdateRatioLimit(address setting, uint96 assetGlobalId, uint newRate) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("updateRatioLimit(uint96,uint256)"));
        bool result = Setting(setting).call(abi.encodeWithSelector(methodId,assetGlobalId,newRate));
        return result;
    }

    function callSetTDC(address finance, address _tdc) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setTDC(address)"));
        bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,_tdc));
        return result;
    }

    function callSetPISseller(address finance, address newSeller) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("setPISseller(address)"));
        bool result = TimefliesFinance(finance).call(abi.encodeWithSelector(methodId,newSeller));
        return result;
    }

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

    function callStartProposal(address VST,uint FuncDataId, uint _startTime,address _targetContract,bytes _param,uint amount,uint96 id) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("startProposal(uint256,uint256,address,bytes)"));
        bool result = PISVoteStandard(VST).call.value(amount,id)(abi.encodeWithSelector(methodId,FuncDataId,_startTime,_targetContract,_param));
        return result;
    }

    function callAddNewVoteParam(address VST, uint _passProportion,bytes4 _func,uint _pisVoteDuration) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("addNewVoteParam(uint256,bytes4,uint256)"));
        bool result = PISVoteStandard(VST).call(abi.encodeWithSelector(methodId,_passProportion,_func,_pisVoteDuration));
        return result;
    }

    function callAddNewVoteParam(address DV,uint _passVotes, uint _passProportion,bytes4 _func,uint _directorVoteDuration, uint _pisVoteDuration) public returns (bool) {
        bytes4 methodId = bytes4(keccak256("addNewVoteParam(uint256,uint256,bytes4,uint256,uint256)"));
        bool result = DirectorVoteContract(DV).call(abi.encodeWithSelector(methodId,_passVotes,_passProportion,_func,_directorVoteDuration,_pisVoteDuration));
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

contract TimefliesVoteDir is DirectorVoteContract,TestTimeflies {
    constructor(address paiMainContract)
    DirectorVoteContract(paiMainContract)
    public {
    }
}