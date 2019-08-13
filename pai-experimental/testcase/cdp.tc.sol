pragma solidity 0.4.25;

// import "../../library/template.sol";
// import "../cdp.sol";
// import "../3rd/test.sol";
// import "../3rd/math.sol";

import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/math.sol";
import "github.com/seeplayerone/dapp-bin/library/template.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/cdp.sol";
import "github.com/seeplayerone/dapp-bin/pai-experimental/3rd/test.sol";

/// this contract is used to simulate `time flies` to test governance fees and stability fees accurately
contract TestTimeflies is DSNote {
    uint256  _era;

    constructor() public {
        _era = now;
    }

    function era() public view returns (uint256) {
        return _era == 0 ? now : _era;
    }

    function fly(uint age) public note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract TimefliesCDP is CDP, TestTimeflies {
    constructor(address _issuer, address _oracle, address _liquidator)
        CDP(_issuer, _oracle, _liquidator)
        public 
    {

    }
    
}

contract CDPTest is Template, DSTest, DSMath {
    TimefliesCDP private cdp;
    constructor(address _cdp) public {
        cdp = TimefliesCDP(_cdp);
    }

    function() public payable {

    }

    //// test when there is enough BTC deposit
    function testBorrowGovernanceFee() public {
        cdp.updateGovernanceFee(1000000003000000000000000000);
        cdp.borrow(1, 100000000);
        cdp.fly(1 days);
        assertEq(100025920, cdp.debtOfCDPwithGovernanceFee(1));
    }
    
}