# Setup Asimov Fullnode

This document briefly introduces how to setup an asimov fullnode and run in either SOLO or TestNet mode.

Prerequisites:

- Basic blockchain knowledges

## Download Package

Download the latest binary file from Asimov [tutorial repository](https://github.com/seeplayerone/dapp-bin/tree/pai-governance/testnet-tutorial/bin).

You will find following files:

- full node binary file ```asimovd```
- sample configuration file ```asimovd.sample.conf```
- checksum `md5.md`

## Configurate Working Directory

Like Bitcoin and Ethereum, it is required to provide enough disk space to run the asimov full node. The default working directory is:

- ```~/.asimovd``` on POSIX OS
- ```$LOCALAPPDATA/Asimovd``` on Windows
- ```~/Library/Application Support/Asimovd``` on Mac OS
- ```$home/asimovd``` on Plan9

You need to create an ```asimovd.conf``` file and put it under the default working directory.

## Configurate ```asimovd.conf```

```asimovd.conf``` contains all configuration parameters to run the asimov full node. Currently, we support 2 running modes:

### SOLO

In this mode, the node plays as the only block producer and rpc service provider in the network. 

```sh
; testnet,regtest,simnet
testnet=1
; solo,poa
consensustype=solo
miningaddr=0x661f34e56d497ceafc9e91945d33d262695c3b7f90
privatekey=0x3cb581f720c265739ef4ab6aaf86264268dcc67648f8ac96119e3a255f565e12
```

### TestNet

In this mode, the node will connect to Asimov testnet and sync up to the latest status of the testnet. The node only plays as the rpc service provider in testnet.

```sh
; testnet,regtest,simnet
testnet=1
; solo,pow,poa,mpos
consensustype=poa
privatekey=0x3cb581f720c265739ef4ab6aaf86264268dcc67648f8ac96119e3a255f565e12

addpeer=52.53.220.36
addpeer=18.162.40.196
```

### Private Key and Address

You need to configurate private key for both SOLO and TestNet mode, and mining address for SOLO mode. How to get them:

1. go to IDE tool [Mnenmonic](https://ide.asimov.tech/#/mnenmonic) page
2. click ```Generate Mnenmonic``` to get a 12-word mnenmonic (save it locally and you can import to create a wallet in Asilink)
3. click ```Generate``` under BIP44 to generate (private key, address) pairs using the above mnenmonic which follows BIP44 standards.

![](./img/node-mnenmonic.png)

Copy any pair of private key and address (the first pair is recommended which is the default when importing the mnenmonic to Asilink wallet) to ```asimovd.conf``` respectively.

### RPC Port

The default rpc listening port is **8545**. If you want to change to another port, add the following line to ```asimovd.conf```:

```sh
httpendpoint=0.0.0.0:8888
```

## Run Asimov Fullnode

Once the working directory and ```asimovd.conf``` are set, you can run the asimov fullnode:

```./asimovd```

If you set the working directory to some location other then the default, you may run with the extra 	```homeDir``` parameter:

```./asimovd homeDir ~/some/other/directory```

## Clean Working Directory

If you want to clean the historical data and run the node from scratch again, do the following:

```sh
cd ~/your/working/directory
rm -rf data state logs
```

## Test RPC

Once the node is up and running, the easist way to verify its RPC service is to test ```faucet``` function in IDE tool and transfer some assets in AsiLink wallet. 

Before test, you need to add a local network entry in AsiLink wallet, as shown below:

![](./img/asilink-add-network.png)

For more information about how to setup AsiLink wallet, please read [AsiLink](./asilink.md);

### FAUCET

Go to IDE tool [FAUCET](https://ide.asimov.tech/#/faucet) page, make sure to switch to local network on the up-right conner and reload the website if necessary. 

If you are running in SOLO mode, set your private key to make the corresponding mining address as the faucet address; otherwise, leave as default. Choose the asset type (**0000000000000000000000** which represents Asim), input the receving address (your wallet address), input the amount then click the ```Send``` button. Open the wallet to verify the test Asim is received successfully.

![](./img/node-faucet.png)

### ASILINK

Open Asilink wallet, click ```Send``` and transfer some test Asim to other address. 