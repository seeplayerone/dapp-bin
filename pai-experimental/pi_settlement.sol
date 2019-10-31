pragma solidity 0.4.25;

import "../library/utils/ds_note.sol";
import "../library/template.sol";
import "./pi_liquidator.sol";
import "./pi_price_oracle.sol";
import "./pi_cdp.sol";
import "../library/acl_slave.sol";

/// @notice Settlement应该要能处理更多的清盘逻辑

contract Settlement is Template, DSNote, ACLSlave {

    CDP private cdp;
    Liquidator private liquidator;
    PriceOracle private oracle;

    constructor(address paiMainContract,address _po, address _cdp, address _lq) public {
        master = ACLMaster(paiMainContract);
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
    function terminatePhaseOne() public note auth("PISVOTE") {
        require(!cdp.settlement());
        oracle.terminate();
        cdp.updateRates();
        cdp.terminate();
        liquidator.cancelDebt();
        liquidator.terminatePhaseOne();
    }

    function terminatePhaseTwo() public note auth("PISVOTE") {
        require(cdp.readyForPhaseTwo());
        liquidator.terminatePhaseTwo();
    }
}