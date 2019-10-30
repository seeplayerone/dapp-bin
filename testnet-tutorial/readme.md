## Asimov Tutorial Project

The target readers of this repository are smart contract and dapp developers on Asimov who should at least have basic knowledge on:

- Blockchain and smart contract
- Ethereum VM and Solidity

### docs

- Documentations on [Asimov node setup](./docs/node.md) and [Asimov chrome wallet](./docs/asilink.md).
- Documentations on Asimov blockchain tools including [Web IDE tool](./docs/ide-tool.md) and [cmd tool](./docs/cmd.md).
- Documentations on Asimov blockchain [Restful RPC API](./docs/rpc.md).
- Documentations on [Contract Development](./docs/tutorial-contract.md).

## src

There is a [tutorial contract](./src/contracts/tutorial.sol) which demostrates how to utilize the exclusive Asimov asset instructions in smart contract. There are also test cases written in both [solidity](./src/tc-solidity/tutorial.tc.sol) and [javascript](./src/tc-javascript/tutorial.tc.js).

## bin

There is a release version of Asimov node binary file with [sample configuration](./bin/asimovd.sample.conf) file.


