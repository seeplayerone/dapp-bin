pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

import "./testPrepareNew.sol";

contract TestBase is Template, DSTest, DSMath {
    event printString(string);
    event printDoubleString(string,string);
    event printAddr(string,address);
    event printNumber(string,uint);
    event printAddrs(string,address[]);

    //others
    FakeBTCIssuer internal btcIssuer;
    FakeBTCIssuer internal ethIssuer;

    //governance
    ProposalData internal proposal;
    TimefliesElection internal coinElection;
    TimefliesPISVote internal PISVote;
    TimefliesPISVote internal pisVote1;
    TimefliesDIRVote internal dirVote1;
    TimefliesDIRVote internal dirVote2;
    TimefliesDemonstration internal demonstration1;
    TimefliesPISVote internal pisVote2;
    TimefliesDIRVote internal dirVote3;
    TimefliesDemonstration internal demonstration2;
    TimefliesPISVote internal pisVote3;
    TimefliesPISVote internal pisVote4;

    //MAIN
    FakePaiDao internal paiDAO;
    FakePAIIssuer internal paiIssuer;
    TimefliesOracle internal pisOracle;
    Setting internal setting;
    Finance internal finance;
    Liquidator internal PISseller;

    //BTC LENDING
    TimefliesOracle internal btcOracle;
    Liquidator internal btcLiquidator;
    TimefliesCDP internal btcCDP;
    Settlement internal btcSettlement;

    //ETH LENDING
    // TimefliesOracle internal ethOracle;
    // Liquidator internal ethLiquidator;
    // TimefliesCDP internal ethCDP;
    // Settlement internal ethSettlement;

    //PAI DEPOSIT
    TimefliesTDC internal tdc;

    //fake person
    FakePerson internal admin;
    FakePerson internal founder;
    FakePerson internal secretary;
    FakePerson internal oracle1;
    FakePerson internal oracle2;
    FakePerson internal oracle3;
    FakePerson internal director1;
    FakePerson internal director2;
    FakePerson internal director3;
    FakePerson internal airDropRobot;
    FakePerson internal CFO;
    FakePerson internal oracleManager;

    //asset
    uint96 internal ASSET_BTC;
    uint96 internal ASSET_ETH;
    uint96 internal ASSET_PIS;
    uint96 internal ASSET_PAI;

    function() public payable {}

    function setup() public {
        //collateral
        btcIssuer = new FakeBTCIssuer();
        btcIssuer.init("BTC");
        ASSET_BTC = uint96(btcIssuer.getAssetType());
        ethIssuer = new FakeBTCIssuer();
        ethIssuer.init("ETH");
        ASSET_ETH = uint96(btcIssuer.getAssetType());

        //fakeperson
        founder = new FakePerson();
        secretary = new FakePerson();
        admin = new FakePerson();
        oracle1 = new FakePerson();
        oracle2 = new FakePerson();
        oracle3 = new FakePerson();
        director1 = new FakePerson();
        director2 = new FakePerson();
        director3 = new FakePerson();
        airDropRobot = new FakePerson();
        CFO = new FakePerson();
        oracleManager = new FakePerson();
        //governance contract deployment and setting
        paiDAO = new FakePaiDao("PAIDAO");
        paiDAO.init();
        ASSET_PIS = paiDAO.PISGlobalId();
        //remove admin
        paiDAO.createNewRole("PISVOTE","ADMIN",0,false);
        paiDAO.addMember(this,"PISVOTE");
        paiDAO.changeTopAdmin("PISVOTE");
        paiDAO.changeSuperior("PISVOTE","PISVOTE");
        paiDAO.removeMember(this,"ADMIN");
        paiDAO.createNewRole("Founder","PISVOTE",0,false);
        paiDAO.changeSuperior("Founder","Founder");
        paiDAO.createNewRole("Secretary","PISVOTE",0,false);
        paiDAO.addMember(secretary,"Secretary");
        paiDAO.changeSuperior("Secretary","Founder");

        proposal = new ProposalData();
        PISVote = new TimefliesPISVote(paiDAO, proposal, RAY/2, RAY/20, 7 days/5, "ADMIN");
        paiDAO.addMember(PISVote,"PISVOTE");
        coinElection = new TimefliesElection(paiDAO,"Director@STCoin","DirectorBackUp@STCoin");
        paiDAO.createNewRole("DirectorElection@STCoin","PISVOTE",0,false);
        paiDAO.createNewRole("Director@STCoin","DirectorElection@STCoin",3,true);
        paiDAO.createNewRole("DirectorBackUp@STCoin","DirectorElection@STCoin",0,false);
        paiDAO.addMember(coinElection,"DirectorElection@STCoin");
        pisVote1 = new TimefliesPISVote(paiDAO, proposal, RAY/2, RAY/20, 7 days/5, "Director@STCoin");
        paiDAO.createNewRole("DirPisVote","PISVOTE",0,false);
        paiDAO.addMember(pisVote1,"DirPisVote");
        paiDAO.addMember(this,"DirPisVote");
        dirVote1 = new TimefliesDIRVote(paiDAO, proposal, 0x0, RAY / 2, 3 days / 5, "Director@STCoin","ADMIN");
        paiDAO.createNewRole("DirVote@STCoin","PISVOTE",0,false);
        paiDAO.addMember(dirVote1,"DirVote@STCoin");
        paiDAO.addMember(this,"DirVote@STCoin");
        pisVote2 = new TimefliesPISVote(paiDAO, proposal, RAY/2, RAY * 2, 7 days/5, "50%Demonstration@STCoin");
        demonstration1 = new TimefliesDemonstration(paiDAO, proposal, pisVote2, RAY / 10, 1 days / 5, "50%DemPreVote@STCoin");
        paiDAO.createNewRole("50%Demonstration@STCoin","PISVOTE",0,false);
        paiDAO.addMember(pisVote2,"50%Demonstration@STCoin");
        paiDAO.addMember(demonstration1,"50%Demonstration@STCoin");
        dirVote2 = new TimefliesDIRVote(paiDAO, proposal, demonstration1, RAY / 2, 3 days / 5, "Director@STCoin","ADMIN");
        paiDAO.createNewRole("50%DemPreVote@STCoin","PISVOTE",0,false);
        paiDAO.addMember(dirVote2,"50%DemPreVote@STCoin");
        pisVote3 = new TimefliesPISVote(paiDAO, proposal, RAY/2, RAY * 2, 7 days/5, "100%Demonstration@STCoin");
        demonstration2 = new TimefliesDemonstration(paiDAO, proposal, pisVote3, RAY / 10, 1 days / 5, "100%DemPreVote@STCoin");
        paiDAO.createNewRole("100%Demonstration@STCoin","PISVOTE",0,false);
        paiDAO.addMember(pisVote3,"100%Demonstration@STCoin");
        paiDAO.addMember(demonstration2,"100%Demonstration@STCoin");
        paiDAO.addMember(this,"100%Demonstration@STCoin");
        dirVote3 = new TimefliesDIRVote(paiDAO, proposal, demonstration2, RAY, 3 days / 5, "Director@STCoin","ADMIN");
        paiDAO.createNewRole("100%DemPreVote@STCoin","PISVOTE",0,false);
        paiDAO.addMember(dirVote3,"100%DemPreVote@STCoin");
        pisVote4 = new TimefliesPISVote(paiDAO, proposal, RAY/2, RAY * 2, 7 days/5, "Director@STCoin");
        paiDAO.createNewRole("DirPisVote@STCoin","PISVOTE",0,false);
        paiDAO.addMember(pisVote4,"DirPisVote@STCoin");

        //delpoy other contract and setting
        //main
        paiIssuer = new FakePAIIssuer("PAIISSUER",paiDAO);
        paiIssuer.init();
        ASSET_PAI = paiIssuer.PAIGlobalId();
        pisOracle = new TimefliesOracle("PISOracle@STCoin", paiDAO, RAY * 100, ASSET_PIS);
        paiDAO.createNewRole("PISOracle@STCoin","PISVOTE",3,false);
        paiDAO.addMember(oracle1,"PISOracle@STCoin");
        paiDAO.addMember(oracle2,"PISOracle@STCoin");
        paiDAO.addMember(oracle3,"PISOracle@STCoin");
        paiDAO.createNewRole("OracleManager@STCoin","DirVote@STCoin",0,false);
        paiDAO.addMember(oracleManager,"OracleManager@STCoin");
        setting = new Setting(paiDAO);
        finance = new Finance(paiDAO,paiIssuer,setting,pisOracle);
        paiDAO.createNewRole("AirDrop@STCoin","PISVOTE",0,false);
        paiDAO.createNewRole("CFO@STCoin","DirVote@STCoin",0,false);
        paiDAO.addMember(airDropRobot,"AirDrop@STCoin");
        paiDAO.addMember(CFO,"CFO@STCoin");
        paiDAO.createNewRole("FinanceContract","100%Demonstration@STCoin",0,false);
        paiDAO.addMember(finance,"FinanceContract");
        paiDAO.createNewRole("Liqudator@STCoin","100%Demonstration@STCoin",0,false);
        paiDAO.createNewRole("TDC@STCoin","100%Demonstration@STCoin",0,false);
        PISseller = new Liquidator(paiDAO,pisOracle, paiIssuer,"ADMIN",finance,setting);
        finance.setPISseller(PISseller);
        //BTC LENDING
        btcOracle = new TimefliesOracle("BTCOracle@STCoin", paiDAO, RAY * 70000, ASSET_PIS);
        paiDAO.createNewRole("BTCOracle@STCoin","PISVOTE",3,false);
        paiDAO.addMember(oracle1,"BTCOracle@STCoin");
        paiDAO.addMember(oracle2,"BTCOracle@STCoin");
        paiDAO.addMember(oracle3,"BTCOracle@STCoin");
        btcLiquidator = new Liquidator(paiDAO,btcOracle, paiIssuer,"BTCCDP@STCoin",finance,setting);
        paiDAO.addMember(btcLiquidator,"Liqudator@STCoin");
        btcCDP = new TimefliesCDP(paiDAO,paiIssuer,btcOracle,btcLiquidator,setting,finance,100000000000);
        paiDAO.createNewRole("Minter@STCoin","PISVOTE",0,false);
        paiDAO.addMember(btcCDP,"Minter@STCoin");
        paiDAO.createNewRole("BTCCDP@STCoin","PISVOTE",0,false);
        paiDAO.addMember(btcCDP,"BTCCDP@STCoin");
        setting.updateRatioLimit(ASSET_BTC, RAY * 2);
        btcSettlement = new Settlement(paiDAO,btcOracle,btcCDP,btcLiquidator);
        paiDAO.createNewRole("Settlement@STCoin","PISVOTE",0,false);
        paiDAO.addMember(btcSettlement,"Settlement@STCoin");

        //ETH LENDING
        // ethOracle = new TimefliesOracle("ETHOracle@STCoin", paiDAO, RAY * 1500, ASSET_ETH);
        // paiDAO.createNewRole("ETHOracle@STCoin","PISVOTE",3,false);
        // paiDAO.addMember(oracle1,"ETHOracle@STCoin");
        // paiDAO.addMember(oracle2,"ETHOracle@STCoin");
        // paiDAO.addMember(oracle3,"ETHOracle@STCoin");
        // ethLiquidator = new Liquidator(paiDAO,ethOracle,paiIssuer,"ETHCDP@STCoin",finance,setting);
        // paiDAO.addMember(ethLiquidator,"Liqudator@STCoin");
        // ethCDP = new TimefliesCDP(paiDAO,paiIssuer,ethOracle,ethLiquidator,setting,finance,30000000000);
        // paiDAO.addMember(ethCDP,"Minter@STCoin");
        // paiDAO.createNewRole("ETHCDP@STCoin","PISVOTE",0,false);
        // paiDAO.addMember(ethCDP,"ETHCDP@STCoin");
        // setting.updateRatioLimit(ASSET_ETH, RAY * 3 / 10);
        // ethSettlement = new Settlement(paiDAO,ethOracle,ethCDP,ethLiquidator);
        // paiDAO.addMember(ethSettlement,"Settlement@STCoin");
        //PAI DEPOSIT

        // tdc = new TimefliesTDC(paiDAO,setting,paiIssuer,finance);
        // finance.setTDC(tdc);
        // paiDAO.addMember(tdc,"TDC@STCoin");

    }
}

contract Print is TestBase {
    function print() public {
        setup();
        paiDAO.removeMember(this,"DirPisVote");
        paiDAO.removeMember(this,"100%Demonstration@STCoin");
        paiDAO.removeMember(this,"DirVote@STCoin");
        paiDAO.removeMember(this,"PISVOTE");
        uint groupNumber = paiDAO.indexOfPG();
        for (uint i = 1; i <= groupNumber; i++) {
            emit printString("===================================================");
            emit printDoubleString("Role:",string(paiDAO.roles(i)));
            emit printDoubleString("Superior:",string(paiDAO.getSuperior(paiDAO.roles(i))));
            emit printNumber("memberLimit:",uint(paiDAO.getMemberLimit(paiDAO.roles(i))));
            emit printAddrs("members:",paiDAO.getMembers(paiDAO.roles(i)));
        }
        emit printString("===================================================");
    }
}

