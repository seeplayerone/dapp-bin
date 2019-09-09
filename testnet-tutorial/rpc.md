# JSON RPC API Reference

## API Method Summary

* [asimov_getBlockChainInfo](#asimov_getBlockChainInfo)
* [asimov_getBlockHash](#asimov_getBlockHash)
* [asimov_upTime](#asimov_upTime)
* [asimov_validateAddress](#asimov_validateAddress)
* [asimov_getCurrentNet](#asimov_getCurrentNet)
* [asimov_getBestBlock](#asimov_getBestBlock)
* [asimov_getBlock](#asimov_getBlock)

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

### [flow_getBlock](#flow_getBlock)

Returns information of block.

#### Parameters

* block hash
* whether to get the details of the block
* whether to get the details of the transactions

#### Returns

* Block and transaction details.


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
                "hex": "......",
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