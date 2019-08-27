pragma solidity 0.4.25;

// import "./3rd/note.sol";
// import "../library/template.sol";
// import "./liquidator.sol";
// import "./pai_issuer.sol";
// import "./cdp.sol";

import "github.com/evilcc2018/dapp-bin/pai-experimental/3rd/note.sol";
import "github.com/evilcc2018/dapp-bin/library/template.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/liquidator.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/price_oracle.sol";
import "github.com/evilcc2018/dapp-bin/pai-experimental/cdp.sol";

contract Settlement is Template, DSNote {

    CDP private cdp;
    Liquidator private liquidator;
    PriceOracle private oracle;

    constructor(address _po, address _cdp, address _lq) public {
        oracle = PriceOracle(_po);
        cdp = CDP(_cdp);
        liquidator = Liquidator(_lq);
    }

    /// terminate business => settlement process starts
    /// there are two phases of settlement
    ///     1. User/system can liquidate all CDPs using the given price without any penalty; only withdraw operation is allowed.
    ///        Liquidator can not sell collateral at this phase.
    ///     2. All CDPs are liquidated, withdraw operation is still allowed if more collaterals are left in CDPs.
    ///        A final collateral price is calculated for users to redeem PAI for collateral from Liquidator.
    function terminatePhaseOne() public note {
        require(!cdp.inSettlement());

        oracle.terminate();

        cdp.updateRates();
        cdp.terminate();

        liquidator.cancelDebt();
        liquidator.terminatePhaseOne();
    }

    function terminatePhaseTwo() public note {
        require(cdp.readyForPhaseTwo());

        liquidator.terminatePhaseTwo();
    }
    
}