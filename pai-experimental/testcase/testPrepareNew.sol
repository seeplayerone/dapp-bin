pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "../../library/template.sol";
import "../testPI.sol";
import "../pai_main.sol";
import "../pai_issuer.sol";
import "../price_oracle.sol";
import "../pai_setting.sol";
import "../pai_finance.sol";
import "../cdp.sol";
import "../tdc.sol";
import "../settlement.sol";
import "../fake_btc_issuer.sol";
import "../pai_election_director.sol";
import "../pai_PISvote.sol";
import "../pai_proposal.sol";
import "../pai_DIRvote.sol";
import "../pai_demonstration.sol";
import "../bank_assistant.sol";
import "../bank_issuer.sol";
import "../bank_finance.sol";
import "../bank_business.sol";


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
}

contract FakePAIIssuer is PAIIssuer {
    constructor(string _organizationName, address paiMainContract)
        PAIIssuer(_organizationName,paiMainContract)
    public {
        templateName = "Fake-Template-Name-For-Test-pai_issuer";
    }
}

contract FakeBankIssuer is BankIssuer {
    constructor(string _organizationName, address paiMainContract)
        BankIssuer(_organizationName,paiMainContract)
    public {
        templateName = "Fake-Template-Name-For-Test-bank_issuer";
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

contract TimefliesElection is PAIElectionDirector,TestTimeflies {
    constructor(address pisContract, string winnerRole, string backupRole)
    PAIElectionDirector(pisContract,winnerRole,backupRole)
    public {
    }
}


contract TimefliesPISVote is PISVote,TestTimeflies {
    constructor(address paiMainContract, address _proposal, uint _passProportion, uint _startProportion, uint _pisVoteDuration, string preVote)
    PISVote(paiMainContract,_proposal,_passProportion,_startProportion,_pisVoteDuration,preVote)
    public {
    }
}

contract TimefliesDIRVote is DIRVote,TestTimeflies {
    constructor(address paiMainContract, address _proposal, address _nextVote, uint _passProportion, uint _voteDuration, string _director, string _originator)
    DIRVote(paiMainContract, _proposal, _nextVote, _passProportion, _voteDuration, _director,_originator)
    public {
    }
}

contract TimefliesDemonstration is Demonstration,TestTimeflies {
    constructor(address paiMainContract, address _proposal, address _nextVote, uint _passProportion, uint _duration, string preVote)
    Demonstration(paiMainContract, _proposal, _nextVote, _passProportion, _duration, preVote)
    public {
    }
}

contract TimefliesBankBusiness is BankBusiness,TestTimeflies {
    constructor(address paiMainContract, address _issuer, address _finance, uint _baseTime)
    BankBusiness(paiMainContract, _issuer, _finance, _baseTime)
    public {
    }
}