# RPC接口文档

## JSON RPC API Reference

* [flow_getBlockChainInfo](#flow_getBlockChainInfo)
* [flow_getBlockHash](#flow_getBlockHash)
* [flow_upTime](#flow_upTime)
* [flow_validateAddress](#flow_validateAddress)
* [flow_getCurrentNet](#flow_getCurrentNet)
* [flow_getBestBlock](#flow_getBestBlock)
* [flow_getBlock](#flow_getBlock)
* [flow_getBlockHeader](#flow_getBlockHeader)
* [flow_getBalance](#flow_getBalance)
* [flow_getBlockList](#flow_getBlockList)
* [flow_getUtxoByAddress](#flow_getUtxoByAddress)
* [flow_getGenesisContractNames](#flow_getGenesisContractNames)
* [flow_getConnectionCount](#flow_getConnectionCount)
* [flow_getInfo](#flow_getInfo)
* [flow_getNetTotals](#flow_getNetTotals)
* [flow_getGenesisContract](#flow_getGenesisContract)
* [flow_getContractTemplateList](#flow_getContractTemplateList)
* [flow_getContractTemplateName](#flow_getContractTemplateName)
* [flow_createRawTransaction](#flow_createRawTransaction)
* [flow_decodeRawTransaction](#flow_decodeRawTransaction)
* [flow_decodeScript](#flow_decodeScript)
* [flow_getMPosCfg](#flow_getMPosCfg)
* [flow_callReadOnlyFunction](#flow_callReadOnlyFunction)
* [flow_getBalances](#flow_getBalances)
* [flow_getRawTransaction](#flow_getRawTransaction)
* [flow_getTransactionReceipt](#flow_getTransactionReceipt)
* [flow_sendRawTransaction](#flow_sendRawTransaction)
* [flow_signRawTransaction](#flow_signRawTransaction)
* [flow_searchRawTransactions](#flow_searchRawTransactions)

## flow_getBlockChainInfo{#flow_getBlockChainInfo}

获取区块链信息

### 参数 

none

### 返回值

* `chain`：网络标识
* `blocks`: 当前块高
* `bestblockhash`：最新的块Hash
* `mediantime`：
* `pruned`：

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBlockChainInfo"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":{
        "chain":"testnet3",
        "blocks":9065,
        "bestblockhash":"ffe409af30d2281be8e92b6f3f2a3f480b54e942cf86c5d0ba6a1fcf2ac3da18",
        "mediantime":1548738280,
        "pruned":false
    }
}
```

## flow_getBlockHash{#flow_getBlockHash}

通过块高获取块Hash

### 参数

* 块高

### 返回值

* 块Hash

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBlockHash","params":[10]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":"34299db811149c3d32dfe63ca7f1c0affc1200799ba56bac47d3561528b4d044"
}
```

## flow_upTime{#flow_upTime}

获取节点运行时间

### 参数

none

### 返回值

* 节点运行时间，单位秒

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_upTime"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":1548744616
}
```



## flow_validateAddress{#flow_validateAddress}

验证地址是否合法

### 参数

* 地址

### 返回值

* 是否合法

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_validateAddress","params":["cRpLDfbzE6sfmkAs2kFcHuX3cDgF7McJbx"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":true
}
```

## flow_getCurrentNet{#flow_getCurrentNet}

获取当前网络环境编号

### 参数

none

### 返回值

* 网络环境编号

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getCurrentNet"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":118034699
}
```

## flow_getBestBlock{#flow_getBestBlock}

获取当前最新的块

### 参数

none

### 返回值

* `hash`：块Hash
* `height`：块高

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBestBlock"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc":"2.0",
    "id":1,
    "result":{
        "hash":"60787b53bc2b30b6c9d8c6dedcd07f8a5650f33daa91004f6a022f7ba79f32ef",
        "height":9788
    }
}
```

## flow_getBlock{#flow_getBlock}

通过块hash获取块信息

### 参数

* 块Hash
* 是否获取块的详细信息
* 是否获取交易的详细信息

### 返回值

* 块和交易的详细信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBlock","params":["60787b53bc2b30b6c9d8c6dedcd07f8a5650f33daa91004f6a022f7ba79f32ef",true,true]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "60787b53bc2b30b6c9d8c6dedcd07f8a5650f33daa91004f6a022f7ba79f32ef",
        "confirmations": 115,
        "size": 646,
        "height": 9788,
        "version": 0,
        "versionHex": "00000000",
        "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
        "rawtx": [
            {
                "hex": "0100000002000000010000000000000000000000000000000000000000000000000000000000000000ffffffff11023c26000c2f503253482f666c6f77642fffffffff010065cd1d0000000023210272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21ac0c0000000000000000000000000000000000",
                "txid": "8e54d258bc6da21b448a7a233b434d1e04f7a8c1c767805c287ffc8c3948ef37",
                "hash": "8e54d258bc6da21b448a7a233b434d1e04f7a8c1c767805c287ffc8c3948ef37",
                "size": 130,
                "version": 1,
                "locktime": 0,
                "vin": [
                    {
                        "coinbase": "023c26000c2f503253482f666c6f77642f",
                        "sequence": 4294967295
                    }
                ],
                "vout": [
                    {
                        "value": 5,
                        "n": 0,
                        "scriptPubKey": {
                            "asm": "0272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21 OP_CHECKSIG",
                            "hex": "210272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21ac",
                            "reqSigs": 1,
                            "type": "pubkey",
                            "addresses": [
                                "mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"
                            ]
                        }
                    }
                ]
            }
        ],
        "time": 1548748523,
        "txCount": 0,
        "previousblockhash": "5031a040f455f7064f490ee31814bdb64560bc57096fbe2cfeaa14d43601ef36",
        "stateroot": "e2f0caab45ceeec27da51cb74eda7597c8ac69ff09744e90d2dcdcf2a62c7255",
        "nextblockhash": "56499f4e4b16a7c0307ca345827b79e05e92cd62610edc1596f72e52bd567058"
    }
}
```

## flow_getBlockHeader{#flow_getBlockHeader}

通过块Hash获取块头信息

### 参数

* 块Hash
* 是否获取块头详细信息

### 返回值

* 块头信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBlockHeader","params":["60787b53bc2b30b6c9d8c6dedcd07f8a5650f33daa91004f6a022f7ba79f32ef",true]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "60787b53bc2b30b6c9d8c6dedcd07f8a5650f33daa91004f6a022f7ba79f32ef",
        "confirmations": 232,
        "height": 9788,
        "version": 0,
        "versionHex": "00000000",
        "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
        "stateroot": "e2f0caab45ceeec27da51cb74eda7597c8ac69ff09744e90d2dcdcf2a62c7255",
        "time": 1548748523,
        "previousblockhash": "5031a040f455f7064f490ee31814bdb64560bc57096fbe2cfeaa14d43601ef36",
        "nextblockhash": "56499f4e4b16a7c0307ca345827b79e05e92cd62610edc1596f72e52bd567058"
    }
}
```

## flow_getBalance{#flow_getBalance}

获取指定地址的余额

### 参数

* 地址

### 返回值

* 资产的余额

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBalance","params":["mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "asset": "000000000000000000000000",
            "value": "51605"
        }
    ]
}
```

## flow_getBlockList{#flow_getBlockList}

批量获取块信息

### 参数

* 起始块高
* 数量

### 返回值

* 块信息列表

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBlockList","params":[0,1]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "hash": "5d04328ec8033e73fb9246d6a00485e3885293ec9d582dbaace09484aeb1dafd",
            "confirmations": 1,
            "size": 0,
            "height": 11181,
            "version": 0,
            "versionHex": "00000000",
            "merkleroot": "0000000000000000000000000000000000000000000000000000000000000000",
            "time": 1548827441,
            "txCount": 1,
            "previousblockhash": "567e7dd52d585a549b06eccf0e62ec97d35bb3510ff5c872ae083526c73c3a11",
            "stateroot": "",
            "nextblockhash": "567e7dd52d585a549b06eccf0e62ec97d35bb3510ff5c872ae083526c73c3a11"
        }
    ]
}
```

## flow_getUtxoByAddress{#flow_getUtxoByAddress}

获取地址上某个资产的UTXO

### 参数

* 地址数组
* 资产（可选）

### 返回值

* UTXO信息数组

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getUtxoByAddress","params":[["mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"],"000000000000000000000000"]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "txid": "09edfaa78802b0947c8c093a73e4a2f214171934515bc1fcde72ed8d6fdd6277",
            "vout": 0,
            "address": "mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS",
            "account": "",
            "scriptPubKey": "210272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21ac",
            "amount": 5,
            "confirmations": 0,
            "spendable": false,
            "assets": "000000000000000000000000"
        }
    ]
}
```

## flow_getGenesisContractNames{#flow_getGenesisContractNames}

获取创世合约名称

### 参数

none

### 返回值

* 创世合约名称列表

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getGenesisContractNames"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        "TemplateWarehouse",
        "GenesisOrg",
        "Recompiled",
        "Registry"
    ]
}
```

## flow_getConnectionCount{#flow_getConnectionCount}

获取连接当前P2P节点的数量

### 参数

none

### 返回值

* 数量

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getConnectionCount"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": 0
}
```

## flow_getInfo{#flow_getInfo}

获取节点信息

### 参数

none

### 返回值

* 节点信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getInfo"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "version": 10000,
        "protocolversion": 1,
        "blocks": 11760,
        "timeoffset": 0,
        "connections": 0,
        "proxy": "",
        "testnet": true,
        "relayfee": 0,
        "errors": ""
    }
}
```

## flow_getNetTotals{#flow_getNetTotals}

获取P2P节点接收和发送的所有字节数

### 参数

none

### 返回值

* 接收、发送的字节数

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getNetTotals"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "totalbytesrecv": 0,
        "totalbytessent": 0,
        "timemillis": 1548837605687
    }
}
```

## flow_getGenesisContract{#flow_getGenesisContract}

通过名称获取创世组织信息

### 参数

* 创世组织名称

### 返回值

* 创世组织信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getGenesisContract","params":["GenesisOrg"]}}' -H "Content-type: application/json" http://localhost:8545/

# Respons
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "address": "cgZP4yZedWo6NsCPzeukTf8qjURw2pUh7L",
        "code": "......",
        "abiInfo": "......",
        "addressHex": "0xAD7bFab37C1A628d2df015402C18095D62CF4825"
    }
}
```

## flow_getContractTemplateList{#flow_getContractTemplateList}

获取合约模板列表

### 参数

* 合约模板是否已通过审核
* 合约模板类型

### 返回值

* 合约模板信息列表

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getContractTemplateList","params":[true,1]}}' -H "Content-type: application/json" http://localhost:8545/

# Respon
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "name": "TemplateName",
            "byteCode": "......",
            "createTime": 1548328442,
            "approveCount": 1,
            "rejectCount": 0,
            "reviewers": 1,
            "status": 1
        }
    ]
}
```

## flow_getContractTemplateName{#flow_getContractTemplateName}

获取合约继承的模板的名称

### 参数

* 合约地址

### 返回值

* 合约继承的模板名称

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getContractTemplateName","params":["cfC1V2mKoX7CZav6grLMGuaAAMpTeUY2Lj"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": "TemplateName"
}
```

## flow_createRawTransaction{#flow_createRawTransaction}

创建交易

### 参数

* 交易类型
* 交易输入数组
* 交易输出数组
* 解锁时间

### 返回值

* 交易Hash以及交易中产生的合约地址

### 示例

```json
# Request
curl -X POST --data '{"jsonrp":"1.0","method":"flow_createRawTransaction","params":[2,[{"txid":"a7eb60008bfc6b25345be10ab27074cf6276f6133a1debe1baf6156f5954ebba","vout":0,"address":"mieQGjCWCk9h13FSXfqQ5tN3zGCbBXDXEN","account":"","scriptPubKey":"21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac","amount":5,"confirmations":0,"spendable":false,"assets":"000000000000000000000000","checked":true,"privateKey":"ugkwX1Hc6zFuprT8PCg4dwnCg91VV2fdm9XipgUWkJ6"}],[{"address":"mvhDTrHsmsaYSKwmYWU81Jz4k2RUM6rHjv","amount":"4","assets":"000000000000000000000000"}],0],"id":1548904273272}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1548904273272,
    "result": {
        "hex": "010000000200000001baeb54596f15f6bae1eb1d3a13f67662cf7470b20ae15b34256bfc8b0060eba70000000000ffffffff010084d717000000001976a914a67ab5700bb942cf79524608c8a0d791912b56a588ac0c0000000000000000000000000000000000",
        "contractaddr": {}
    }
}
```

## flow_decodeRawTransaction{#flow_decodeRawTransaction}

从交易Hex中解码出交易的原始信息

### 参数

* 交易原始Hex

### 返回值

* 交易信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_decodeRawTransaction","params":["010000000200000001baeb54596f15f6bae1eb1d3a13f67662cf7470b20ae15b34256bfc8b0060eba70000000000ffffffff010084d717000000001976a914a67ab5700bb942cf79524608c8a0d791912b56a588ac0c0000000000000000000000000000000000"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "txid": "6a983fda6cd8e3a52e2274f3170424317a122f4958bc9f0a39b0d151932d6251",
        "version": 1,
        "locktime": 0,
        "vin": [
            {
                "txid": "a7eb60008bfc6b25345be10ab27074cf6276f6133a1debe1baf6156f5954ebba",
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
                    "asm": "OP_DUP OP_HASH160 a67ab5700bb942cf79524608c8a0d791912b56a5 OP_EQUALVERIFY OP_CHECKSIG",
                    "hex": "76a914a67ab5700bb942cf79524608c8a0d791912b56a588ac",
                    "reqSigs": 1,
                    "type": "pubkeyhash",
                    "addresses": [
                        "mvhDTrHsmsaYSKwmYWU81Jz4k2RUM6rHjv"
                    ]
                }
            }
        ]
    }
}
```

## flow_decodeScript{#flow_decodeScript}

解析脚本

### 参数

* 脚本Hash

### 返回值

* 脚本信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_decodeScript","params":["21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "asm": "028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1 OP_CHECKSIG",
        "reqSigs": 1,
        "type": "pubkey",
        "addresses": [
            "mieQGjCWCk9h13FSXfqQ5tN3zGCbBXDXEN"
        ],
        "p2sh": "2N3wFPhjLo9yiVSRSvd8yo6riye896axjQ9"
    }
}
```

## flow_getMPosCfg{#flow_getMPosCfg}

获取MPos配置

### 参数

none

### 返回值

* MPos配置信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getMPosCfg"}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "subsidyHalvingInterval": 985500,
        "powLimit": 1.766847064778384329583297500742918515827483896875618958121606201292619775e+72,
        "posLimit": 2.6959946667150639794667015087019630673637144422540572481103610249215e+67,
        "powTargetTimespan": 960,
        "powTargetSpacing": 128,
        "ifPowAllowMinDifficultyBlocks": false,
        "ifPowNoRetargeting": true,
        "ifPoSNoRetargeting": false,
        "lastPOWBlock": 5000,
        "mPoSRewardRecipients": 10,
        "firstMPoSBlock": 10,
        "fixUTXOCacheHFHeight": 100000,
        "minimumChainWork": null,
        "defaultAssumeValid": null
    }
}
```

## flow_callReadOnlyFunction{#flow_callReadOnlyFunction}

调用合约的view、pure方法

### 参数

* 合约地址
* 入参(input)
* 调用的方法名
* 合约abi

### 返回值

* 方法返回值

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_callReadOnlyFunction","params":["cfC1V2mKoX7CZav6grLMGuaAAMpTeUY2Lj","2fb97c1d","getTemplateInfo","[{\"constant\": true,\"inputs\": [],\"name\": \"getTemplateInfo\",\"outputs\": [{\"name\": \"\",\"type\": \"uint16\"},{\"name\": \"\",\"type\": \"string\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": true,\"inputs\": [],\"name\": \"getInfo\",\"outputs\": [{\"name\": \"\",\"type\": \"string\"},{\"name\": \"\",\"type\": \"uint256\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_fName\",\"type\": \"string\"},{\"name\": \"_age\",\"type\": \"uint256\"}],\"name\": \"setInfo\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_category\",\"type\": \"uint16\"},{\"name\": \"_templateName\",\"type\": \"string\"}],\"name\": \"initTemplate\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"anonymous\": false,\"inputs\": [{\"indexed\": false,\"name\": \"name\",\"type\": \"string\"},{\"indexed\": false,\"name\": \"age\",\"type\": \"uint256\"}],\"name\": \"Instructor\",\"type\": \"event\"}]"]}}' -H "Content-type: application/json" http://localhost:8545/

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

## flow_getBalances{#flow_getBalances}

获取指定地址列表的余额

### 参数

* 地址列表

### 返回值

* 余额信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getBalances","params":[["mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"]]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "address": "mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS",
            "assets": [
                {
                    "asset": "000000000000000000000000",
                    "value": "67565"
                }
            ]
        }
    ]
}
```

## flow_getRawTransaction{#flow_getRawTransaction}

获取交易原始信息

### 参数

* 交易ID
* 是否获取详细信息
* 是否获取VIN额外信息

### 返回值

* 交易原始信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getRawTransaction","params":["981b3384da1590132e54eda337f085c2f15351102f1133f60b3b19367c1afda7",true,true]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hex": "......",
        "txid": "981b3384da1590132e54eda337f085c2f15351102f1133f60b3b19367c1afda7",
        "hash": "981b3384da1590132e54eda337f085c2f15351102f1133f60b3b19367c1afda7",
        "size": 482,
        "version": 1,
        "locktime": 0,
        "vin": [
            {
                "txid": "75ebf477835daa53d275ebbe262324d1a2e1dc2eb14e7450f857081f63c1b156",
                "vout": 0,
                "scriptSig": {
                    "asm": "304402202ec3d7407e0defd9d1180a400d7be15c5d610a45b475ee768ea4b3dfdd46b133022078ee8f569bbd41613406992d29a886950323f6f083f44d55b3b647a6642ae54f01",
                    "hex": "47304402202ec3d7407e0defd9d1180a400d7be15c5d610a45b475ee768ea4b3dfdd46b133022078ee8f569bbd41613406992d29a886950323f6f083f44d55b3b647a6642ae54f01"
                },
                "sequence": 4294967295
            }
        ],
        "vout": [
            {
                "value": 0,
                "n": 0,
                "scriptPubKey": {
                    "asm": "OP_CALL 9bf20ec8c2e2fc6c988d33e78ee9913ea9e29509",
                    "hex": "c2149bf20ec8c2e2fc6c988d33e78ee9913ea9e29509",
                    "type": "call",
                    "addresses": [
                        "0x9bf20ec8c2e2fc6c988d33e78ee9913ea9e29509"
                    ]
                }
            },
            {
                "value": 4,
                "n": 1,
                "scriptPubKey": {
                    "asm": "OP_DUP OP_HASH160 6e55294d0ee2b7306b9a765b576df9c8ed73a877 OP_EQUALVERIFY OP_CHECKSIG",
                    "hex": "76a9146e55294d0ee2b7306b9a765b576df9c8ed73a87788ac",
                    "reqSigs": 1,
                    "type": "pubkeyhash",
                    "addresses": [
                        "mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"
                    ]
                }
            }
        ],
        "blockhash": "7ba06dc539c986fedc5d6539949ebad619d59c802d41d50434d00ea96352a916",
        "confirmations": 6,
        "time": 1550459668,
        "blocktime": 1550459668
    }
}
```

## flow_getTransactionReceipt{#flow_getTransactionReceipt}

获取交易的收据

### 参数

* 交易ID

### 返回值

* 交易收据信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_getTransactionReceipt","params":["2758af1c23208bcc0ac14890466ed74ecca11c881ed2220d3db3707fee707752"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "root": "0x3f728ce62e44bc2eba6b6a718e0a3c63b38606866aa175b4037b753c31d57ed1",
        "status": "0x0",
        "cumulativeGasUsed": "0x0",
        "logsBloom": "......",
        "logs": [
            {
                "address": "0x91bb2b90b244e0ec20786099d919e21e6a4989f1",
                "topics": [
                    "0x010becc10ca1475887c4ec429def1ccc2e9ea1713fe8b0d4e9a1d009042f6b8e"
                ],
                "data": "......",
                "blockNumber": "0x1d5",
                "transactionHash": "2758af1c23208bcc0ac14890466ed74ecca11c881ed2220d3db3707fee707752",
                "transactionIndex": "0x1",
                "blockHash": "0c98403416eb235f2cc1c5ba6ebbe3f0f981e00fbf772013f4b7de0269b39844",
                "logIndex": "0x0",
                "removed": false
            }
        ],
        "transactionHash": "2758af1c23208bcc0ac14890466ed74ecca11c881ed2220d3db3707fee707752",
        "contractAddress": "0x0000000000000000000000000000000000000000",
        "gasUsed": "0x0"
    }
}
```

## flow_sendRawTransaction{#flow_sendRawTransaction}

发送交易到节点

### 参数

* 交易Hex

### 返回值

* 交易Hash

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_sendRawTransaction","params":["01000000020000000179a4e055158f02ba715d20eaa24e2b7271fe62ea800ef8891c6241887e0a4dc4000000004847304402203b2796a83f0ae794f865e4abb27cab63b1c631a00909ac9b0f87bf4a17412a7002204c88d59d79bde14fbc0133484248ecf865b9a9918c37a79b3ac9a711f893230e01ffffffff010084d717000000001976a914a67ab5700bb942cf79524608c8a0d791912b56a588ac0c0000000000000000000000000000000000"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "error": {
        "code": -32000,
        "message": "-22: TX rejected: orphan transaction d379872daa0444a57f525358c5bf600317837ed554cf696ec8f5c75f5892088e references outputs of unknown or fully-spent transaction c44d0a7e8841621c89f80e80ea62fe71722b4ea2ea205d71ba028f1555e0a479"
    }
}
```

## flow_signRawTransaction{#flow_signRawTransaction}

交易签名

### 参数

* 交易原始信息：rawTx
* 原始TxInput数组
* 签名类型："ALL"、"NONE"、"SINGLE"、"ALL|ANYONECANPAY"、"NONE|ANYONECANPAY"、"SINGLE|ANYONECANPAY"

### 返回值

* 交易签名之后的信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_signRawTransaction","params":["01000000020000000118484462e85c41fbcff8434123a78d3c0474bab5804245ae297f9539030510030000000000ffffffff010084d717000000001976a914a67ab5700bb942cf79524608c8a0d791912b56a588ac0c0000000000000000000000000000000000",[{"txid":"0310050339957f29ae454280b5ba74043c8da7234143f8cffb415ce862444818","vout":0,"address":"mieQGjCWCk9h13FSXfqQ5tN3zGCbBXDXEN","account":"","scriptPubKey":"21028ff24dc9bf0a9020a191f734815ace4bcce694c280b5d380883138577737ebb1ac","amount":5,"confirmations":0,"spendable":false,"assets":"000000000000000000000000","checked":true,"privateKey":"ugkwX1Hc6zFuprT8PCg4dwnCg91VV2fdm9XipgUWkJ6"}],"ALL"]}}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hex": "01000000020000000118484462e85c41fbcff8434123a78d3c0474bab5804245ae297f9539030510030000000049483045022100aef4beefe383a959f140f238ecfd1040f7637cc59a38b68dc363ba4a238d6a960220143ac9ce161ef89692339b7626928208f1ec1bb041b26ac9d32be7e861d8b48401ffffffff010084d717000000001976a914a67ab5700bb942cf79524608c8a0d791912b56a588ac0c0000000000000000000000000000000000",
        "complete": true
    }
}
```

## flow_searchRawTransactions{#flow_searchRawTransactions}

搜索指定地址的原始交易

### 参数

* 想要获取交易的地址
* 是否获取详细信息
* 获取交易的起始坐标
* 获取交易的数量
* 是否获取上一个交易德OutPut
* 是否逆序显式
* 需要过滤德地址

### 返回值

* 交易信息

### 示例

```json
# Request
curl -X POST --data '{"id":1, "jsonrpc":"2.0","method":"flow_searchRawTransactions","params":["mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS",true,0,1,false,false,[]]}' -H "Content-type: application/json" http://localhost:8545/

# Response
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "hex": "0100000002000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0f51000c2f503253482f666c6f77642fffffffff010065cd1d0000000023210272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21ac0c0000000000000000000000000000000000",
            "txid": "67a1dc65a272af1662914a7551f8499b7c8a6963f9f5330da269d5ad0b1bac1f",
            "hash": "",
            "size": "",
            "vsize": "",
            "version": 1,
            "locktime": 0,
            "vin": [
                {
                    "coinbase": "51000c2f503253482f666c6f77642f",
                    "sequence": 4294967295
                }
            ],
            "vout": [
                {
                    "value": 5,
                    "n": 0,
                    "scriptPubKey": {
                        "asm": "0272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21 OP_CHECKSIG",
                        "hex": "210272c732edcbd766dffe511acbbc7e150d01d6109f4b904780d4a60b42acc60f21ac",
                        "reqSigs": 1,
                        "type": "pubkey",
                        "addresses": [
                            "mqaLeGXL45agrJirqmkYD6RMsXnw26c3aS"
                        ]
                    }
                }
            ],
            "blockhash": "1b9bc299a094c892d6aa716ca4c073f5c7f92f826f8e1b4369039c5fe2562af1",
            "confirmations": 298,
            "time": 1550824072,
            "blocktime": 1550824072
        }
    ]
}
```