# JSON RPC API Reference

## API Method Summary

* [asimov_getBlockChainInfo](#asimov_getBlockChainInfo)

## API Methods

---

### asimov_getBlockChainInfo

Returns the information of block chain

#### Parameters

none

#### Returns

- `chain`: current network type
- `blocks`:number of blocks
- `bestblockhash`:current block hash
- `mediantime`：
- `pruned`：

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