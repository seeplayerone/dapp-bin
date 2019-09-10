# JSON RPC API Reference

## API Method Summary

* [asimov_getBlockChainInfo](#asimov_getBlockChainInfo)
* [asimov_getBlockHash](#asimov_getBlockHash)
* [asimov_upTime](#asimov_upTime)
* [asimov_validateAddress](#asimov_validateAddress)
* [asimov_getCurrentNet](#asimov_getCurrentNet)
* [asimov_getBestBlock](#asimov_getBestBlock)
* [asimov_getBlock](#asimov_getBlock)
* [asimov_getBlockHeader](#asimov_getBlockHeader)
* [asimov_getBalance](#asimov_getBalance)
* [asimov_getBalances](#asimov_getBalances)
* [asimov_getBlockListByHeight](#asimov_getBlockListByHeight)
* [asimov_getUtxoByAddress](#asimov_getUtxoByAddress)
* [asimov_getNetTotals](#asimov_getNetTotals)

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