# Document Overview

This document provides a brief description of how to develop, test, and deploy smart contracts on the Asimov platform.

Prerequistes:

- Blockchain and smart contract
- Ethereum VM and Solidity 

## Develop Contract

The Asimov virtual machine is compatible with EVM. We recommend using [Solidity](https://solidity.readthedocs.io/en/v0.4.25/) as the development language for smart contracts. Developing contracts on Asimov are almost the same as on Ethereum. 

Asimov has made some improvements based on EVM and developers need to be aware of following things:

- ```staticCall``` ```callCode``` ```delegateCall``` These three methods allow the called contract to change the storage space of the calling contract, which is a security risk, and Asimov will no longer support them.

- ```create``` ```new``` Both methods deploy new contracts inside the contract by calling ```opCreate``` instruction. Asimov introduces the design of TEMPLATE, and provides a new ```deployContract``` method to support the deployment of new contracts within the contract. ```create``` and ```new``` are only available in test mode.

- ```send``` ```transfer``` ```value``` Asimov introduces the design of MUTXO, and asset transfer requires an additional **assettype**. New ```transfer``` method and ```call``` method are provided to support that.

> Asimov adpots Solidity version 0.4.25, and Solidity features in newer version will not be supported at this stage.


### TEMPLATE

On the Asimov platform, users need to upload the developed smart contract to the Asimov template warehouse from the [IDE tool](https://ide.asimov.tech/#/) or [Developer Center](https://developer.asimov.network/), which then becomes a template. The corresponding contract instance is then deployed based on the template.

Two important things to note related to template when developing smart contracts:

- All template contracts need to inherit the [Template](https://github.com/seeplayerone/dapp-bin/blob/master/library/template.sol) base contract directly or indirectly.
- When deploying new contract inside a contract, use the ```flow.deployContract()``` method.

-------

```flow.deployContract(uint16 category, string name, bytes params)```

Deploy a new contract inside a contract. 

- **category** template cateory.
- **name** template name. The template category and template name are set when the template is created.
- **params** contract initialization parameters.


### MUTXO

All assets on the Asimov platform are native UTXO assets. We designed **assettype** to distinguish different types of UTXO.

Note a contract needs to register to Asimov platform and get an organization ID before issuing assets. This is demostrated in the [Tutorial](https://github.com/seeplayerone/dapp-bin/blob/master/testnet-tutorial/tutorial.sol).

> Regarding the definition of the above **assettype** parameter, as shown in the following figure: the organization with an Organization ID of 25 (hexadecimal, 00000025 in the middle part) issued two assets, with the index 0 and 1 respectively (00000000 and 00000001 in the right part). Properties are both defaults to 00000000 which is a normal fungible asset (00000000 in the left part).

![](./img/contract-asset-96bit.png)

-------

```flow.createAsset(uint32 properties, uint32 index, uint amount)```

Create a new UTXO asset inside the contract.

- **properties** 32bit long asset properties.
- **index** 32bit long asset index inside an orgnization.
- **amount** the number of assets to create.

-------

```flow.mintAsset(uint32 index, uint amount)```

Issue additional UTXO asset inside the contract.

- **index** 32bit long asset index inside an orgnization.
- **amount** the number of assets to mint.

-------

```flow.balance(address dest, uint96 assettype)```

Get balance of a specific asset on a given address.

- **dest** the address to fetch balance of.
- **assettype** the assettype to fetch balance of.

-------

```to.transfer(uint amount, uint96 assettype)```
```to.call.value(uint amount, uint96 assettype)```

Transfer asset to a specific address.

- **to** destination address.
- **amount** the number of assets to transfer. 
- **assettype** the assettype to transfer.

-------

```msg.asset()```

Get the assettype of the transaction inside a contract. Returns **assettype** as defined above.

### Tutorial Project

We have created a [tutorial project](https://github.com/seeplayerone/dapp-bin/tree/master/testnet-tutorial) to demostrate how to develop a simple contract to experience the exclusive features of Asimov described above.

## Test Contract

We recommend to adopt a **Test Driven Development** paradigm for contract development.

Once finish designing and implementing a smart contract, it is a good practice to write thorough unit tests to fully cover every single function uint of a contract. There are usually two ways to write test cases for a contract, either using other smart contracts or through js library. Both of them are introduced below.

### Test using Solidity

We have provided a [test contract](https://github.com/seeplayerone/dapp-bin/tree/pai-governance/testnet-tutorial/src/tc-solidity/tutorial.tc.sol) in the tutorial project. 

We can run a test contract in "test mode" in IDE tool: we don't need to create a template for the test contract or the target contract it is testing against, and the execution is not state perserving. In order to support that, ```new``` and ```create``` are enabled in "test mode".

Go to the IDE [Test](https://ide.asimov.tech/#/test) page: 

- on the lefe pane of the page, upload folders/files.
- choose the file need to test, it displays on the ide pane in the middle.
- edit the source file if necessary. 
- click ```Compile``` to compile the test contract.
- click the ```Console```tab on the bottom pane.
- select the contract instance to test agianst, as shown in the figure below we choose ```TutorialTest```. 
- select the specific test function to execute, as shown in the figure below we choose ```test```.
- click ```Test``` button and you can see the test result in the console.
- click ```Test All``` button will execute all functions with **test** prefix in the selected contract instance.

![](./img/contract-test.png)

> Note the folder system on the left pane are shared with the [EXECUTE](https://ide.asimov.tech/#/run/execute) page.

### Test using Javascript

We have provided a [test javascript](https://github.com/seeplayerone/dapp-bin/tree/pai-governance/testnet-tutorial/src/tc-javascript/tutorial.tc.js) in the tutorial project. 

The javascript test cases are written based on [@asimovdev/asimov-cli](https://www.npmjs.com/package/@asimovdev/asimov-cli) and [@asimovdev/asimovjs](https://www.npmjs.com/package/@asimovdev/asimov-cli) libraries. You need to have node and npm installed.

Run ```node tutorial.tc.js``` in the test folder and you will see something like below in the console. 

![](./img/contract-test-js.png)

## Deploy Contract

After thorough tests, you may deploy your contract through the IDE tool.

As we adpots the TEMPLATE design, there are three sub steps to deploy/run a contract on Asimov.

**Contract Source File** --submit--> **Asimov Template** --deploy--> **Contract Instance** --execute-->

### Create Contract Template

Go to the IDE [SUBMIT](https://ide.asimov.tech/#/run/submit) page:

- choose the file you need to submit as template from the left pane.
- input template name and choose template category (As shown in the figure below, the name is ```tutorial-1``` and the category is ```Organization```).
- click ```Compile File``` to compile the contract.
- choose the contract instance used to create the template (As shown below, ```Tutorial```).
- click the ```Create Contract Template``` button to invoke the AsiLink wallet plugin to submit the transaction.

![](./img/contract-submit-template.png)

### Deploy Contract Instance

Go to the IDE [DEPLOY](https://ide.asimov.tech/#/run/deploy) page:

- find the contract template you just created.
- click the ```Deploy``` button and fill in the initialization parameters.
- click the ```Deploy``` button to invoke the AsiLink wallet plugin to submit the transaction.

After the contract instance is deployed successfully, the AsiLink wallet will return the address of the instance and please save the address for the next steps.

![](./img/contract-deploy-contract-success.png)

### Call Contract Functions


Go to the IDE [EXECUTE](https://ide.asimov.tech/#/run/execute) page:

- input the contract address saved in the previous step and click ```Search Contract```.
- after loading the contract template, select the function you want to execute on the right pane (As shown in the figure below, the function is ```mint```).
- click the ```Call Function``` button to invoke the AsiLink wallet plugin to submit the transaction.
- click the ```Balance``` tab on the buttom pane to verify the asset has been mint.

![](./img/contract-call-contract.png)