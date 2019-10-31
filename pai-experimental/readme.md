# PAI Experimental

There are 4 smart contracts in design v0.1

- **pi_cdp.sol** Handles basic CDP operations, including create - transfer and close a CDP, deposit and withdraw BTC', borrow and repay PAI, liqudate unsafe CDPs.
- **pi_liquidator.sol** Handles liquidated BTC' and debts(-PAI).
- **pi_price_oracle.sol** Provides BTC' price agianst PAI.
- **pi_issuer.sol** Mints and burns PAI stable coin. 

## Debug

1. Deploy **pi_price_oracle.sol** and set BTC' price (call ```updatePrice()``` function). Note the price is calculated in RAY (RAY=10<sup>27</sup>, which represents 1). Save address as **a1**.
2. Deploy **pi_issuer.sol**. Initialize the issuer (call ```init()``` function). Save address as **a2**.
3. Depoly **pi_liquidator.sol**. Before that, make sure to set price oracle and pai issuer addresses with **a1** and **a2** from above steps. Save address as **a3**.
4. Deploy **pi_cdp.sol**. Before that, make sure to set price oracle, pai issuer and liquidator addresses with **a1**, **a2** and **a3** from above steps.