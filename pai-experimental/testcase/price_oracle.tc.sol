pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../price_oracle.sol";
// import "../3rd/test.sol";

import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/test.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/testcase/testPrepare.sol";


contract PriceOracleTest is Template, DSTest,DSMath {
    TimefliesOracle private oracle;
    function testInit() public {
        FakePaiDao paiDAO;
        FakePerson p1 = new FakePerson();

        paiDAO = FakePaiDao(p1.createPAIDAO("PAIDAO"));
        paiDAO.init();
        oracle = new TimefliesOracle("BTCOracle",paiDAO,RAY);

    }
}