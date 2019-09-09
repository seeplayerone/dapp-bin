# JSON RPC API Reference

## API Method Summary

* [asimov_getBlockChainInfo](#asimov_getBlockChainInfo)
* [asimov_getBlockHash](#asimov_getBlockHash)
* [asimov_upTime](#asimov_upTime)

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