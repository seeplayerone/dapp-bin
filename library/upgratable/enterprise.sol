pragma solidity 0.4.25;

import "./SafeMath.sol";
import "./organization.sol";

contract Enterprise is Organization {
    
    /// use this field to store the number of completely deposit
    uint private depositCount = 0;
    
    struct Partner {
        /// 股权币金额
        uint stockAmount;
        /// 为了更精准的表示股权百分比，这里的数值要乘以1000，例如千分之一百，这里就是100
        uint percent;
        /// 已充值的金额
        uint transferredAmount;
        bool existed;
    }
    
    mapping(address => Partner) partners;
    
    /// partner addresses for acl control
    address[] partnerAddresses;
    /// only designated asset can be deposited
    uint private DEFAULT_ASSET = 0;
    
    constructor(string _organizationName, address[] _partners, uint[] _stockAmount, uint[] _percent, address[] _members)
        Organization(_organizationName, _members) 
        public
    {
        uint partnersL = _partners.length;
        uint stockAmountL = _stockAmount.length;
        uint percentL = _percent.length;
        require(partnersL > 0 && stockAmountL > 0 && percentL > 0, "params can not be empty");
        require(partnersL == stockAmountL && stockAmountL == percentL, "illegal params's length");
        
        partnerAddresses = new address[](0);
        for (uint i = 0; i < partnersL; i++) {
            Partner storage partner = partners[_partners[i]];
            partner.stockAmount = _stockAmount[i];
            partner.percent = _percent[i];
            partner.transferredAmount = 0;
            partner.existed = true;
            partners[_partners[i]] = partner;
            partnerAddresses.push(_partners[i]);
        }
    }

    /**
     * @dev method for members to deposit till they completely it.
     */
    function deposit() public payable authAddresses(partnerAddresses) {
        require(msg.assettype == DEFAULT_ASSET, "not supported asset");
        
        Partner storage partner = partners[msg.sender];
        uint remainAmount = SafeMath.sub(partner.stockAmount, partner.transferredAmount);
        require(remainAmount > 0, "no need to deposit more coin");
        
        if (msg.value <= remainAmount) {
            partner.transferredAmount = SafeMath.add(partner.transferredAmount, msg.value);
        } else {
            partner.transferredAmount = SafeMath.add(partner.transferredAmount, remainAmount);
            msg.sender.transfer(SafeMath.sub(msg.value, remainAmount), msg.assettype);
        }
        if (partner.stockAmount == partner.transferredAmount) {
            depositCount++;
        }
    }
    
    /**
     * @dev method for members to transfer asset to other members
     *  the premise is that everyone has completed the deposit
     * 
     * @param to transfer to address
     * @param amount transfer amount
     */
    function transfer(address to, uint amount) public authAddresses(partnerAddresses) {
        require(depositCount == partnerAddresses.length, "deposit task havent been done");
        require(msg.sender != to, "it is not allowed to transfer to yourself");
        require(amount > 0, "amount must bigger than zero");
        
        Partner storage fromPartner = partners[msg.sender];
        require(fromPartner.stockAmount > 0, "not enough coin to transfer");
        require(fromPartner.stockAmount >= amount, "amount must smaller than account amount");
        
        Partner storage toPartner = partners[to];
        require(toPartner.existed, "target address is not one of the member");
        
        uint transferPercent = SafeMath.div(
            SafeMath.mul(amount, fromPartner.percent),
            fromPartner.stockAmount
        );
        fromPartner.stockAmount = SafeMath.sub(fromPartner.stockAmount, amount);
        toPartner.stockAmount = SafeMath.add(toPartner.stockAmount, amount);
        
        fromPartner.percent = SafeMath.sub(fromPartner.percent, transferPercent);
        toPartner.percent = SafeMath.add(toPartner.percent, transferPercent);
    }
    
}
