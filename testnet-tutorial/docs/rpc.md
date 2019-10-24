# JSON RPC API Reference

## API Method Summary

### block

* [asimov_getBlockChainInfo](#asimov_getBlockChainInfo)
* [asimov_getBlockHash](#asimov_getBlockHash)
* [asimov_getBestBlock](#asimov_getBestBlock)
* [asimov_getBlock](#asimov_getBlock)
* [asimov_getBlockHeader](#asimov_getBlockHeader)
* [asimov_getBlockListByHeight](#asimov_getBlockListByHeight)

### node

* [asimov_upTime](#asimov_upTime)
* [asimov_getCurrentNet](#asimov_getCurrentNet)
* [asimov_getNetTotals](#asimov_getNetTotals)
* [asimov_currentPeers](#asimov_currentPeers)

### helper

* [asimov_validateAddress](#asimov_validateAddress)
* [asimov_decodeScript](#asimov_decodeScript)

### balance

* [asimov_getBalance](#asimov_getBalance)
* [asimov_getBalances](#asimov_getBalances)
* [asimov_getUtxoByAddress](#asimov_getUtxoByAddress)

### transaction

* [asimov_createRawTransaction](#asimov_createRawTransaction)
* [asimov_decodeRawTransaction](#asimov_decodeRawTransaction)
* [asimov_getRawTransaction](#asimov_getRawTransaction)
* [asimov_getTransactionReceipt](#asimov_getTransactionReceipt)
* [asimov_sendRawTransaction](#asimov_sendRawTransaction)
* [asimov_signRawTransaction](#asimov_signRawTransaction)
* [asimov_searchRawTransactions](#asimov_searchRawTransactions)
* [asimov_searchAllRawTransactions](#asimov_searchAllRawTransactions)
* [asimov_getMempoolTransactions](#asimov_getMempoolTransactions)

### system contract

* [asimov_getGenesisContract](#asimov_getGenesisContract)
* [asimov_getGenesisContractByHeight](#asimov_getGenesisContractByHeight)

### contract

* [asimov_getContractTemplateList](#asimov_getContractTemplateList)
* [asimov_getContractTemplate](#asimov_getContractTemplate)
* [asimov_callReadOnlyFunction](#asimov_callReadOnlyFunction)
* [asimov_getContractTemplateInfoByName](#asimov_getContractTemplateInfoByName)
* [asimov_getContractTemplateInfoByKey](#asimov_getContractTemplateInfoByKey)

## API Methods

---

### asimov_getBlockChainInfo

Returns the information of block chain.

#### Parameters

none

#### Returns

- `chain`: current network type
- `blocks`: number of blocks
- `bestblockhash`: current block hash
- `mediantime`：the median time of the past 11 block timestamp
- `pruned`：whether reclaiming disc space

#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBlockChainInfo"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "chain": "testnet",
        "blocks": 4,
        "bestblockhash": "334384fd09eabd15674b71c5d798cd6083779bc344d3b717318fd7d83a1b14f0",
        "mediantime": 1567650227,
        "pruned": false
    }
}
```

---

### [asimov_getBlockHash](#asimov_getBlockHash)

Returns block hash.

#### Parameters

* block height

#### Returns

* `result`: block hash


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBlockHash","params":[10]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": "4361f835ae730de388cdc35f3fdad15f8a9f59b402a9974888f4a9aad9a1d642"
}
```
---

### asimov_upTime

Returns running time of node.

#### Parameters

none

#### Returns

`result`: running seconds 


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_upTime"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": 68
}
```
---

### asimov_validateAddress

Validate given address.

#### Parameters

* address

#### Returns

* `result`: legal or not


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_validateAddress","params":["0x63000000000000000000000000000000000000006a"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": true
}
```
---

### asimov_getCurrentNet

Returns current network identity.

#### Parameters

none

#### Returns

* `result`: network identity


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getCurrentNet"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": 118034699
}
```
---

### asimov_getBestBlock

Returns the hightest block of chain.

#### Parameters

none

#### Returns

* `hash`: block hash
* `height`: block height 


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBestBlock"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "4b0d3df98b4b52165f4c579f0bdf86f308e4ce3f2539fee68a4d253a2a8ea56d",
        "height": 1184
    }
}
```
---

### asimov_getBlock

Returns information of block.

#### Parameters

* block hash
* whether to get the details of the block
* whether to get the details of the transactions

#### Returns

* block and transaction details


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBlock","params":["4b0d3df98b4b52165f4c579f0bdf86f308e4ce3f2539fee68a4d253a2a8ea56d",true,true]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "4b0d3df98b4b52165f4c579f0bdf86f308e4ce3f2539fee68a4d253a2a8ea56d",
        "confirmations": 59,
        "size": 655,
        "height": 1184,
        "version": 536870912,
        "versionHex": "20000000",
        "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
        "rawtx": [
            {
                "hex": "0100000001000000000000......",
                "txid": "b3864f91920528c8594513851baf99f043b3e2855e0ed876c8f13d6aea6bc6f4",
                "hash": "b3864f91920528c8594513851baf99f043b3e2855e0ed876c8f13d6aea6bc6f4",
                "size": 123,
                "version": 1,
                "locktime": 0,
                "vin": [
                    {
                        "coinbase": "02a004000e2f503253482f6173696d6f76642f",
                        "sequence": 4294967295
                    }
                ],
                "vout": [
                    {
                        "value": 1000,
                        "n": 0,
                        "scriptPubKey": {
                            "asm": "OP_DUP OP_HASH160 666e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_IFLAG_EQUALVERIFY OP_CHECKSIG",
                            "hex": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
                            "reqSigs": 1,
                            "type": "pubkeyhash",
                            "addresses": [
                                "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"
                            ]
                        },
                        "data": "",
                        "asset": "000000000000000000000000"
                    }
                ],
                "gaslimit": 0,
                "gasused": 0
            }
        ],
        "time": 1568029109,
        "txCount": 0,
        "previousblockhash": "35bd9793201c81da940c2fd62966a9619a01ef04be8ab4d1c588b4b6dab8a7e0",
        "stateroot": "e0faee16c5ff783cadc4ceb5e1e0587415e7b354351121b226d0da303671a892",
        "nextblockhash": "5dcc0a3fdd4443d294cffe92b9afc99880318049b82679a96208422b45dfcaeb",
        "round": 0,
        "slot": 0
    }
}
```
---

### asimov_getBlockHeader

Returns information of block header.

#### Parameters

* block hash
* whether to get the details of  the block header

#### Returns

* block header detail


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBlockHeader","params":["4b0d3df98b4b52165f4c579f0bdf86f308e4ce3f2539fee68a4d253a2a8ea56d",true]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "4b0d3df98b4b52165f4c579f0bdf86f308e4ce3f2539fee68a4d253a2a8ea56d",
        "confirmations": 131,
        "height": 1184,
        "version": 536870912,
        "versionHex": "20000000",
        "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
        "stateroot": "e0faee16c5ff783cadc4ceb5e1e0587415e7b354351121b226d0da303671a892",
        "time": 1568029109,
        "previousblockhash": "35bd9793201c81da940c2fd62966a9619a01ef04be8ab4d1c588b4b6dab8a7e0",
        "nextblockhash": "5dcc0a3fdd4443d294cffe92b9afc99880318049b82679a96208422b45dfcaeb",
        "gaslimist": 160000000,
        "gasused": 2583
    }
}
```
---

### asimov_getBalance

Returns balance of given address

#### Parameters

* address

#### Returns

* balance of assets


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBalance","params":["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "asset": "000000000000000000000000",
            "value": "2818000"
        }
    ]
}
```
---

### asimov_getBalances

Returns balance of given addresses

#### Parameters

* addresses

#### Returns

* balance of assets


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBalances","params":[["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"]]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "address": "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877",
            "assets": [
                {
                    "asset": "000000000000000000000000",
                    "value": "2877000"
                }
            ]
        }
    ]
}
```
---

### asimov_getBlockListByHeight

Returns block list.

#### Parameters

* block height offset
* number of blocks

#### Returns

* block list


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getBlockListByHeight","params":[1,1]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "hash": "d999b02caa6dd0dd7cea55cd9a1d7bd4bfcbbfcd431fea5d8fb8304b42ec9cc2",
            "confirmations": 3023,
            "size": 653,
            "height": 1,
            "version": 536870912,
            "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
            "rawtx": [
                {
                    "hex": "01000000010000000000000000......",
                    "txid": "4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",
                    "hash": "4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",
                    "size": 121,
                    "version": 1,
                    "locktime": 0,
                    "vin": [
                        {
                            "coinbase": "51000e2f503253482f6173696d6f76642f",
                            "sequence": 4294967295
                        }
                    ],
                    "vout": [
                        {
                            "value": 1000,
                            "n": 0,
                            "scriptPubKey": {
                                "asm": "OP_DUP OP_HASH160 666e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_IFLAG_EQUALVERIFY OP_CHECKSIG",
                                "hex": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
                                "reqSigs": 1,
                                "type": "pubkeyhash",
                                "addresses": [
                                    "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"
                                ]
                            },
                            "data": "",
                            "asset": "000000000000000000000000"
                        }
                    ],
                    "blockhash": "d999b02caa6dd0dd7cea55cd9a1d7bd4bfcbbfcd431fea5d8fb8304b42ec9cc2",
                    "confirmations": 3023,
                    "time": 1568011152,
                    "blocktime": 1568011152,
                    "gaslimit": 0,
                    "gasused": 0
                }
            ],
            "time": 1568011152,
            "txCount": 1,
            "previousblockhash": "ca9807c89dbcf8a5d58cd16545f603ab896e08895bab4f84a8a9a377e7f6789a",
            "stateroot": "",
            "round": 0,
            "slot": 0,
            "gaslimit": 470778607,
            "gasused": 2541,
            "reward": 1000
        }
    ]
}
```
---

### asimov_getUtxoByAddress

Returns UTXO of given address.

#### Parameters

* address
* asset (optional, "")

#### Returns

* UTXO information


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getUtxoByAddress","params":[["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"],"000000000000000000000000"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "txid": "b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c85",
            "vout": 0,
            "address": "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877",
            "account": "",
            "scriptPubKey": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
            "amount": 1000,
            "confirmations": 0,
            "spendable": false,
            "assets": "000000000000000000000000"
        },
        {
            "txid": "bb4948fdcc0ad22a70f1fdae7d489d769c5b3315cf6f6a8cb5cbfa03a390e0d2",
            "vout": 0,
            "address": "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877",
            "account": "",
            "scriptPubKey": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
            "amount": 1000,
            "confirmations": 0,
            "spendable": false,
            "assets": "000000000000000000000000"
        }
    ]
}
```
---

### asimov_getNetTotals

Returns bytes of received and sent.

#### Parameters

none

#### Returns

* information of net


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getNetTotals"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "totalbytesrecv": 0,
        "totalbytessent": 0,
        "timemillis": 1568096785830
    }
}
```
---

### asimov_createRawTransaction

Creat an raw transaction.

#### Parameters

* transaction inputs
* transaction outputs
* lock time

#### Returns

* information of raw transaction


#### Example
```json
# Request
curl -X POST --data '{"jsonrp":"1.0","method":"asimov_createRawTransaction","params":[[{"txid":"b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c85","vout":0,"address":"0x666e55294d0ee2b7306b9a765b576df9c8ed73a877","account":"","scriptPubKey":"21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac","amount":5,"confirmations":0,"spendable":false,"assets":"000000000000000000000000","checked":true,"privateKey":"0xe7f95cb9426ffe0061cea3319b96a133d724056f9d0c6b75e62ff813fea3c9b3"}],[{"address":"0x666e55294d0ee2b7306b9a765b576df9c8ed73a877","amount":"4","assets":"000000000000000000000000"}],0],"id":1548904273272}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1548904273272,
    "result": {
        "hex": "0100000001b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c850000000000ffffffff010084d717000000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000",
        "contractaddr": {}
    }
}
```
---

### asimov_decodeRawTransaction

Decode given raw transaction

#### Parameters

* encoded transaction's hex

#### Returns

* information of raw transaction


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_decodeRawTransaction","params":["0100000001b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c850000000000ffffffff010084d717000000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "txid": "5f6143bcab099d57cb7ba68bf89e3e7d3202592df47b4cd309cafabf20a6c830",
        "version": 1,
        "locktime": 0,
        "vin": [
            {
                "txid": "b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c85",
                "vout": 0,
                "scriptSig": {
                    "asm": "",
                    "hex": ""
                },
                "sequence": 4294967295
            }
        ],
        "vout": [
            {
                "value": 4,
                "n": 0,
                "scriptPubKey": {
                    "asm": "OP_DUP OP_HASH160 666e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_IFLAG_EQUALVERIFY OP_CHECKSIG",
                    "hex": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
                    "reqSigs": 1,
                    "type": "pubkeyhash",
                    "addresses": [
                        "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"
                    ]
                },
                "data": "",
                "asset": "000000000000000000000000"
            }
        ]
    }
}
```
---

### asimov_decodeScript

Decode script.

#### Parameters

* script hash

#### Returns

* information of script


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_decodeScript","params":["21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "asm": "028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1 OP_CHECKSIG",
        "reqSigs": 1,
        "type": "pubkey",
        "addresses": [
            "0x662250f9452ac336daaeee722615619d2ba1422793"
        ],
        "p2sh": "0x73754311709241987b9b4d09fd57848589dab10b17"
    }
}
```
---

### asimov_getGenesisContract

Returns genesis contract at current block height.

#### Parameters

* address of genesis contract

#### Returns

* information of genesis contract


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getGenesisContract","params":["0x630000000000000000000000000000000000000067"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "address": "0x630000000000000000000000000000000000000067",
        "code": "608060405234801561001057600080fd5b50613fc98061002......",
        "abiInfo": "......",
        "addressHex": "0x630000000000000000000000000000000000000067"
    }
}
```
---

### asimov_getGenesisContractByHeight

Returns genesis contract at given block height.

#### Parameters

* block height
* address of genesis contract

#### Returns

* abi of genesis contract


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getGenesisContractByHeight","params":[10,"0x630000000000000000000000000000000000000067"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "exist": true,
        "abi": "[{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"}],\"name\":\"enable\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"index\",\"type\":\"uint256\"}],\"name\":\"getApprovedTemplate\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"}],\"name\":\"reject\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"}],\"name\":\"getSubmittedTemplatesCount\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"}],\"name\":\"approve\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"THRESHOLD\",\"outputs\":[{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"},{\"name\":\"_key\",\"type\":\"bytes32\"}],\"name\":\"create\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"}],\"name\":\"approveForTest\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"index\",\"type\":\"uint256\"}],\"name\":\"getSubmittedTemplate\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[],\"name\":\"init\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"_name\",\"type\":\"string\"}],\"name\":\"disable\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"},{\"name\":\"name\",\"type\":\"string\"}],\"name\":\"getTemplate\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"},{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"ALL_APPROVER\",\"outputs\":[{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_category\",\"type\":\"uint16\"}],\"name\":\"getApprovedTemplatesCount\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}]"
    }
}
```
---

### asimov_getContractTemplateList

Returns contract template list.

#### Parameters

* approved or not
* category

#### Returns

* contract template list


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getContractTemplateList","params":[true,1]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "name": "vote01",
            "key": "14d84139e497e1fbeb8016721aaa44d279444c17fa199ce239dcccc80f0a44ae",
            "createTime": 1567581114,
            "approveCount": 1,
            "rejectCount": 0,
            "reviewers": 1,
            "status": 1
        }
    ]
}
```
---

### asimov_getContractTemplate

Returns template info of contract.

#### Parameters

* contract address

#### Returns

* template info


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getContractTemplate","params":["0x638d214fce47190f4b49cb84947a6f9a44ac482ff4"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "template_name": "TemplateName",
        "template_type": 1
    }
}
```
---

### asimov_callReadOnlyFunction

Call contract's pure or view function.

#### Parameters

* caller address
* contract address
* input data
* function name
* contract abi

#### Returns

* return value of function


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_callReadOnlyFunction","params":["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877","0x638d214fce47190f4b49cb84947a6f9a44ac482ff4","2fb97c1d","getTemplateInfo","[{\"constant\": true,\"inputs\": [],\"name\": \"getTemplateInfo\",\"outputs\": [{\"name\": \"\",\"type\": \"uint16\"},{\"name\": \"\",\"type\": \"string\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": true,\"inputs\": [],\"name\": \"getInfo\",\"outputs\": [{\"name\": \"\",\"type\": \"string\"},{\"name\": \"\",\"type\": \"uint256\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_fName\",\"type\": \"string\"},{\"name\": \"_age\",\"type\": \"uint256\"}],\"name\": \"setInfo\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_category\",\"type\": \"uint16\"},{\"name\": \"_templateName\",\"type\": \"string\"}],\"name\": \"initTemplate\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"anonymous\": false,\"inputs\": [{\"indexed\": false,\"name\": \"name\",\"type\": \"string\"},{\"indexed\": false,\"name\": \"age\",\"type\": \"uint256\"}],\"name\": \"Instructor\",\"type\": \"event\"}]"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        1,
        "TemplateName"
    ]
}
```
---

### asimov_getRawTransaction

Returns raw transaction.

#### Parameters

* transaction hash
* get detail information or not
* get extra vin or not

#### Returns

* information of raw


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getRawTransaction","params":["4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",true,true]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hex": "010000000100000000000000......",
        "txid": "4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",
        "hash": "4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",
        "size": 121,
        "version": 1,
        "locktime": 0,
        "vin": [
            {
                "coinbase": "51000e2f503253482f6173696d6f76642f",
                "sequence": 4294967295
            }
        ],
        "vout": [
            {
                "value": 1000,
                "n": 0,
                "scriptPubKey": {
                    "asm": "OP_DUP OP_HASH160 666e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_IFLAG_EQUALVERIFY OP_CHECKSIG",
                    "hex": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
                    "reqSigs": 1,
                    "type": "pubkeyhash",
                    "addresses": [
                        "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"
                    ]
                },
                "data": "",
                "asset": "000000000000000000000000"
            }
        ],
        "blockhash": "d999b02caa6dd0dd7cea55cd9a1d7bd4bfcbbfcd431fea5d8fb8304b42ec9cc2",
        "confirmations": 4607,
        "time": 1568011152,
        "blocktime": 1568011152,
        "gaslimit": 0,
        "gasused": 0
    }
}
```
---

### asimov_getTransactionReceipt

Returns receipt of given transaction hash.

#### Parameters

* transaction hash

#### Returns

* information of receipt


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getTransactionReceipt","params":["22afe58927c8a7d8a25f10297db4a9a936a2beb68bb9a65a1667c2bb918b623a"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "root": "0xe0faee16c5ff783cadc4ceb5e1e0587415e7b354351121b226d0da303671a892",
        "status": "0x0",
        "cumulativeGasUsed": "0x0",
        "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "logs": [],
        "transactionHash": "22afe58927c8a7d8a25f10297db4a9a936a2beb68bb9a65a1667c2bb918b623a",
        "contractAddress": "0x000000000000000000000000000000000000000000",
        "gasUsed": "0x0"
    }
}
```
---

### asimov_sendRawTransaction

Sent raw transaction to block chain.

#### Parameters

* transaction hex

#### Returns

* transaction hash


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_sendRawTransaction","params":["0100000001b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c850000000000ffffffff010084d717000000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "error": {
        "code": -32000,
        "message": "-22: TX rejected: failed to validate input 5f6143bcab099d57cb7ba68bf89e3e7d3202592df47b4cd309cafabf20a6c830:0 which references output b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c85:0 - index 0 is invalid for stack size 0 (input script bytes , prev output script bytes 76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac)"
    }
}
```
---

### asimov_signRawTransaction

Sign raw transaction.

#### Parameters

* raw transaction
* transaction inputs
* sign type: "ALL"、"NONE"、"SINGLE"、"ALL|ANYONECANPAY"、"NONE|ANYONECANPAY"、"SINGLE|ANYONECANPAY"

#### Returns

* sign result


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_signRawTransaction","params":["0100000001b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c850000000000ffffffff010084d717000000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000",[{"txid":"b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c85","vout":0,"address":"0x666e55294d0ee2b7306b9a765b576df9c8ed73a877","account":"","scriptPubKey":"21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac","amount":5,"confirmations":0,"spendable":false,"assets":"000000000000000000000000","checked":true,"privateKey":"0xe7f95cb9426ffe0061cea3319b96a133d724056f9d0c6b75e62ff813fea3c9b3"}],"ALL"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hex": "0100000001b607d5f75ed6015f4355958b32c62d54da008628c1ba9dc6b0996241d7b37c8500000000484730440220711c4b5408c700a033e28f21e14b814851129f489524822bbd183e6413d9b81b02201e09cda45557f33fada8553694937d34505157bcbce78c9aed9a2e66c801fa8101ffffffff010084d717000000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000",
        "complete": true
    }
}
```
### asimov_searchRawTransactions

Returns raw transactions.

#### Parameters

- transaction associated address
- get detail or not
- transaction offset
- number of transactions
- get last output or not
- reverse or not
- addresses not included

#### Returns

* information of raw transaction


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_searchRawTransactions","params":["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877",true,0,1,false,false,[]]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "hex": "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff1151000e2f503253482f6173696d6f76642fffffffff0100e87648170000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000",
            "txid": "4930275d7d82676d7d2855d300a0e7b990c0f8327d9dae958ac56cabfada6d18",
            "hash": "",
            "size": "",
            "vsize": "",
            "version": 1,
            "locktime": 0,
            "vin": [
                {
                    "coinbase": "51000e2f503253482f6173696d6f76642f",
                    "sequence": 4294967295
                }
            ],
            "vout": [
                {
                    "value": 1000,
                    "n": 0,
                    "scriptPubKey": {
                        "asm": "OP_DUP OP_HASH160 666e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_IFLAG_EQUALVERIFY OP_CHECKSIG",
                        "hex": "76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac",
                        "reqSigs": 1,
                        "type": "pubkeyhash",
                        "addresses": [
                            "0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"
                        ]
                    },
                    "data": "",
                    "asset": "000000000000000000000000"
                }
            ],
            "blockhash": "d999b02caa6dd0dd7cea55cd9a1d7bd4bfcbbfcd431fea5d8fb8304b42ec9cc2",
            "confirmations": 5461,
            "time": 1568011152,
            "blocktime": 1568011152,
            "gaslimit": 470778607,
            "gasused": 2541
        }
    ]
}
```
---

### asimov_searchAllRawTransactions

Return all raw transactions of given addresses.

#### Parameters

* transaction associated addresses
* get detail or not
* get last output or not
* reverse or not

#### Returns

* information of raw transaction


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_searchAllRawTransactions","params":[["0x666e55294d0ee2b7306b9a765b576df9c8ed73a877"],false,false,false]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff1151000e2f503253482f6173696d6f76642fffffffff0100e87648170000001a76a915666e55294d0ee2b7306b9a765b576df9c8ed73a877c5ac0c000000000000000000000000000000000000000000"
    ]
}
```
---

### asimov_getMempoolTransactions

 Returns transactions in mempool.

#### Parameters

* transaction hash array

#### Returns

* information of transaction


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getMempoolTransactions","params":[["22afe58927c8a7d8a25f10297db4a9a936a2beb68bb9a65a1667c2bb918b623a"]]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {}
}
```
---

### asimov_getContractTemplateInfoByName

Returns information of contract template.

#### Parameters

* category
* template name

#### Returns

* information of contract template


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getContractTemplateInfoByName","params":[1, "btefo"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "category": 1,
        "template_name": "btefo",
        "byte_code": "6080604052604051620083923803806200839283398......",
        "abi": "......",
        "source": "solidity source code"
    }
}
```
---

### asimov_getContractTemplateInfoByKey

Returns information of contract template.

#### Parameters

* template key

#### Returns

* information of contract template


#### Example
```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_getContractTemplateInfoByKey","params":["14d84139e497e1fbeb8016721aaa44d279444c17fa199ce239dcccc80f0a44ae"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "category": 1,
        "template_name": "vote01",
        "byte_code": "6080604052600060025534801561001557600080fd5......",
        "abi": "......",
        "source": "pragma solidity 0.4.25;......"
    }
}
```
---

### asimov_currentPeers

return current connected peers.

#### Parameters

None

#### Returns

* peer ip list

#### Example

````json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"asimov_currentPeers"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        "192.168.4.102:49519"
    ]
}
````

