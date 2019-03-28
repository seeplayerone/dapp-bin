pragma solidity 0.4.25;

import "./string_utils.sol";
import "./SafeMath.sol";
import "./template.sol";

/// @dev the Instructions interface
///  Instructions is a system contract
interface Instructions {
    function transfer(address to, bytes12 asset, uint256 amount) external;
    function asset() external returns (bytes12);
}

/// @dev ACL interface
///  ACL is provided by Flow Kernel
interface ACL {
    function canPerform(address _caller, string _functionHash) external view returns (bool);
}

contract MarketMaking is Template {
    using SafeMath for uint256;
    
    bytes12 assetType1;
    bytes12 assetType2;
    
    uint assetType1Amount;
    uint assetType2Amount;
    
    /// multiple 100
    uint ratio;
    Instructions instructions;
    /// ACL interface reference
    ACL acl;
    
    /// functionHash - ACL through the organization contract
    string constant DEPOSIT_FUNCTION = "DEPOSIT_FUNCTION";
    string constant WITHDRAW_FUNCTION = "WITHDRAW_FUNCTION";
    
    constructor(bytes12 _asset1, bytes12 _asset2, uint _ratio, address _instructionsAddress, address _organizationContract)
        public
    {
        assetType1 = _asset1;
        assetType2 = _asset2;
        assetType1Amount = 0;
        assetType2Amount = 0;
        ratio = _ratio;
        instructions = Instructions(_instructionsAddress);
        acl = ACL(_organizationContract);
    }
    
    /// @dev ACL through functionHash
    ///  Note all ACL mappings are kept in the organization contract
    ///  An organization can deploy multiple vote contracts from the same template
    ///  As a result, the functionHash is generated combining contract address and functionHash string
    modifier authFunctionHash(string func) {
        require(acl.canPerform(msg.sender, StringLib.strConcat(StringLib.convertAddrToStr(this), func)));
        _;
    }
    
    function() public payable {
        // exchange(msg.sender, instructions.asset(), msg.value);
    }
    
    /// @dev exchange can be called by external account directly, 
    ///  or can be called by the Scheduer system contract. 
    ///  when called by external account, asset is also sent to the method,
    ///  as a result we need to check whether the asset/amount are match with the transaction.
    ///  when called by the Scheduer system contract, asset is transferred beforehand,
    ///  as a result no asset/amount check is needed.
    function exchange(address destination, bytes12 asset, uint amount)
        public
        payable
        returns (bytes12, uint)
    {
        /// if it is called by the Scheduer system contract, comment; otherwise, check
        if (0xe2f726e84c98e9d14E729d82e78E366EBde056FB != msg.sender) {
            bytes12 instructionAsset = instructions.asset();
            require(instructionAsset == asset, "not supported asset type");
            require(asset == assetType1 || asset == assetType2, "not supported asset type");
            require(msg.value == amount, "amount error");
            require(amount > 0, "amount must bigger than zero");
        }
        
        bytes12 exchangedAsset;
        uint exchangedAmount;
        if (asset == assetType1) {
            exchangedAsset = assetType2;
            exchangedAmount = SafeMath.div(SafeMath.mul(amount, 100), ratio);
            require(exchangedAmount <= assetType2Amount, "not enough amount to exchange");
            
            /// update contract state after successful transfer to prevent re-entry attack
            instructions.transfer(destination, assetType2, exchangedAmount);
            assetType2Amount = SafeMath.sub(assetType2Amount, exchangedAmount);
        }
        if (asset == assetType2) {
            exchangedAsset = assetType1;
            exchangedAmount = SafeMath.div(SafeMath.mul(amount, ratio), 100);
            require(exchangedAmount <= assetType1Amount, "not enough amount to exchange");
            
            instructions.transfer(destination, assetType1, exchangedAmount);
            assetType1Amount = SafeMath.sub(assetType2Amount, exchangedAmount);
        }
        return (exchangedAsset, exchangedAmount);
    }
    
    function estimate(bytes12 asset, uint amount)
        public
        view
        returns(bool, uint, string)
    {
        if (asset != assetType1 && asset != assetType2) {
            return (false, 0, "not supported asset type");
        }
        if (amount <= 0) {
            return (false, 0, "amount must bigger than zero");
        }
        
        uint exchangeAmount;
        if (asset == assetType1) {
            exchangeAmount = SafeMath.div(SafeMath.mul(amount, 100), ratio);
            if (exchangeAmount > assetType2Amount) {
                return (false, 0, "not enough amount to exchange");
            }
            return (true, exchangeAmount, "");
        }
        if (asset == assetType2) {
            exchangeAmount = SafeMath.div(SafeMath.mul(amount, ratio), 100);
            if (exchangeAmount > assetType1Amount) {
                return (false, 0, "not enough amount to exchange");
            }
            return (true, exchangeAmount, "");
        }
    }
    
    function deposit()
        public
        payable 
        // authFunctionHash(DEPOSIT_FUNCTION)
        returns(bool, string)
    {
        uint amount = msg.value;
        bytes12 asset = instructions.asset();
        require(asset == assetType1 || asset == assetType2, "not supported asset type");
        require(amount > 0, "amount must bigger than zero");
        
        if (asset == assetType1) {
            assetType1Amount = SafeMath.add(assetType1Amount, amount);
        }
        if (asset == assetType2) {
            assetType2Amount = SafeMath.add(assetType2Amount, amount);
        }
        return (true, "");
    }
    
    function withdraw(bytes12 asset, uint amount, address destination)
        public
        // authFunctionHash(WITHDRAW_FUNCTION)
        returns(bool, string)
    {
        if (asset != assetType1 && asset != assetType2) {
            return (false, "not supported asset type");
        }
        if (amount <= 0) {
            return (false, "amount must bigger than zero");
        }
        
        if (asset == assetType1) {
            if (amount > assetType1Amount) {
                return (false, "not enough amount to withdraw");
            }
            instructions.transfer(destination, asset, amount);
            assetType1Amount = SafeMath.sub(assetType1Amount, amount);
        }
        if (asset == assetType2) {
            if (amount > assetType2Amount) {
                return (false, "not enough amount to withdraw");
            }
            instructions.transfer(destination, asset, amount);
            assetType2Amount = SafeMath.sub(assetType2Amount, amount);
        }

        return (true, "");
    }
    
}
