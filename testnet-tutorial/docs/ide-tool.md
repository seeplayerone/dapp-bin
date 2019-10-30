# IDE Tool

This document briefly introduces the features of Asimov [IDE Tool](https://ide.asimov.tech). At this moment IDE tool is the most important tool provided by Asimov to develop/test smart contracts.

> As we are still developing Asimov chain, the IDE tool will also be updated rapidly. Besides the IDE Tool, we also provide the full functional [CMD Tool](./cmd.md).

## Network

Similar to AsiLink wallet, you can switch and add new network configuration in the IDE tool from the up-right conner:

![](./img/ide-network.png)

## Block and UTXO

You can view the latest block information on [BLOCK](https://ide.asimov.tech/#/blockchain) page, and search for specific utxos on [UTXO](https://ide.asimov.tech/#/utxo) page.

> Note that the block and utxo information provided by the IDE tool are raw data from PRC service. For better experiences, please view them on [AScan-TestNet](https://ascan.asimov.network/). 

## RUN

As elabrated in [Tutorial of Contract Development](tutorial-contract.md), we adopt TEMPLATE design:

**Contract Source File** --submit--> **Asimov Template** --deploy--> **Contract Instance** --execute-->

### Submit

You can go to [Submit](https://ide.asimov.tech/#/run/submit) page to upload contract source code and create tempates on chain. You can upload folders/files and do basic IDE operations (add/delete file, change file contents, etc) on this page.

> Note the folders/files are shared with the [Test](https://ide.asimov.tech/#/test) page described below.

### Deploy

All submitted tempates will display on [Deploy](https://ide.asimov.tech/#/run/deploy) page. For now, everyone can see others' templates as well. Find the template you need and provide the initialization parameters, you then can deploy a contract instance based on the template and have its address returned.

> You can have a better experience creating templates and deploying instances from the [Asimov Developers-TestNet](https://developer.asimov.network/) portal.

### Execute

You can execute contract functions and on [Execution](https://ide.asimov.tech/#/run/execute) page. The details of execution is elabrated in [Tutorial of Contract Development](tutorial-contract.md) document.

## Test

We recommend "test driven development" paradigm for contract developing. Developers should write thorough testcases before submit a TEMPLATE on asimov. In test mode, we bypass the TEMPLATE precedure for convenience. You can test contracts on [Test](https://ide.asimov.tech/#/test) page. The details of test elabrated is in [Tutorial of Contract Development](tutorial-contract.md) document.

## Faucet

You can fetch test Asim (the asimov system asset) from the [FAUCET](https://ide.asimov.tech/#/faucet) page. Details on how to do that are provided in [AsiLink](./asilink.md). You can also config the private key of the faucet on this page if you setup your own developing environment.

> At the moment, you can set solidity compiler version on this page as well. The default compiler is **asimov.js**.

## Mnenmonic

We provide easy access for developers to generate mnemonic and private key/address pairs based on BIP44 on [Mnenmonic](https://ide.asimov.tech/#/mnenmonic) page.
