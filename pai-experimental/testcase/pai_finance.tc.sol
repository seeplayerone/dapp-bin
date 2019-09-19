pragma solidity 0.4.25;

import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";


contract TestBase is Template, DSTest, DSMath {
    TimefliesTDC internal tdc;
    Liquidator internal liquidator;
    TimefliesOracle internal oracle;
    FakePAIIssuer internal paiIssuer;
    FakeBTCIssuer internal btcIssuer;
    FakePerson internal admin;
    FakePerson internal p1;
    FakePerson internal p2;
    FakePaiDao internal paiDAO;
    Setting internal setting;
    TimefliesFinance internal finance;

    uint96 internal ASSET_BTC;
    uint96 internal ASSET_PAI;

    function() public payable {}

    function setup() public {
        admin = new FakePerson();
        p1 = new FakePerson();
        p2 = new FakePerson();
        paiDAO = FakePaiDao(admin.createPAIDAO("PAIDAO"));
        paiDAO.init();
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());

        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY * 10,ASSET_BTC);
        admin.callCreateNewRole(paiDAO,"BTCOracle","ADMIN",3);
        admin.callCreateNewRole(paiDAO,"DIRECTORVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"PISVOTE","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"SettlementContract","ADMIN",0);
        admin.callCreateNewRole(paiDAO,"BTCCDP","ADMIN",0);
        admin.callAddMember(paiDAO,admin,"BTCOracle");
        admin.callAddMember(paiDAO,p1,"BTCOracle");
        admin.callAddMember(paiDAO,p2,"BTCOracle");
        admin.callAddMember(paiDAO,admin,"DIRECTORVOTE");
        admin.callAddMember(paiDAO,admin,"PISVOTE");
        admin.callAddMember(paiDAO,admin,"SettlementContract");
        admin.callAddMember(paiDAO,admin,"BTCCDP");

        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();

        setting = new Setting(paiDAO);
    //     finance = new TimefliesFinance(paiDAO,paiIssuer,setting);
    //     liquidator = new Liquidator(paiDAO,oracle, paiIssuer,"BTCCDP",finance,setting);
    //     admin.callUpdateRatioLimit(setting, ASSET_BTC, RAY * 2);

    //     admin.callCreateNewRole(paiDAO,"PAIMINTER","ADMIN",0);
    //     admin.callAddMember(paiDAO,admin,"PAIMINTER");

    //     tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
    //     //finance.init(tdc);

    //     btcIssuer.mint(100000000000, p1);
    //     btcIssuer.mint(100000000000, p2);
    //     btcIssuer.mint(100000000000, this);
    //     admin.callMint(paiIssuer,100000000000,p1);
    //     admin.callMint(paiIssuer,100000000000,p2);
    //     admin.callMint(paiIssuer,100000000000,this);
    }
}