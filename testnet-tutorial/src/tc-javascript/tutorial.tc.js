const { rpc } = require("@asimovdev/asimov-cli/scripts/rpc")
call = require("@asimovdev/asimov-cli/scripts/call")
template = require("@asimovdev/asimov-cli/scripts/template")

path = require('path')
colors = require('colors')
assert = require('assert')

var source = path.resolve(__dirname, '../contracts/tutorial.sol');
var privateKey = '91ab6c021cbe1e489f259dfae308b5328f0647e65ffd2d529fb9a61a593917c4';
var address = '0x66fbecbfcb831851bb3d4629a9bc72372e785e5895';
var category = 1;
var gas = 100000000;
var value = 0;
var type = '000000000000000000000000'

function checkTx(_tid) {
    let queryLoop = (_tid, resolve, reject) => {
        let count = 0
        let queryCount = 10
        rpc.getTransactionReceipt(_tid).then(res => {
            console.log('wait for transaction to be confirmed on chain ...')
            if (!res) {
                count++
                if (count >= queryCount) {
                reject(0)
                return
                }
                setTimeout(() => {
                queryLoop(_tid, resolve, reject)
                }, 5000)
            } else if (res.status == 1) {
                resolve(1)
                return
            } else {
                reject(0)
                return
            }
        })
    }

    return new Promise((resolve, reject) => {
        queryLoop(_tid, resolve, reject)
    })
}

function checkAddress(_address) {
    let queryLoop = (_address, resolve, reject) => {
        let count = 0
        let queryCount = 10
        rpc.getContractTemplate(_address.toString()).then(res => {
            console.log('wait for transaction to be confirmed on chain ...')
            if (res.template_type == 0) {
                count++
                if (count >= queryCount) {
                reject(0)
                return
                }
                setTimeout(() => {
                queryLoop(_address, resolve, reject)
                }, 5000)
            } else {
                resolve(1)
                return
            }
        })
    }

    return new Promise((resolve, reject) => {
        queryLoop(_address, resolve, reject)
    })
}

function intTo24Hex(value) {
    var str = parseInt(value, 10).toString(16);
    while(str.length < 24){
        str = "0" + str;
    }
    return str;
}

var temp = "template_" + Date.now();
var args = [];
args.push(temp);

async function testTutorial() {
    var _tid;
    var _address;
    var _type;

    /// create template from source file
    /// there can be more than one contracts after compilation, choose one by its name
    console.log(colors.yellow('create template: ') + colors.green(temp))
    await template.createTemplateWithContractName(source, temp, category, gas, privateKey, "Tutorial").then(res => {
        _tid = res;
    })

    await checkTx(_tid)
    console.log(colors.yellow('template created successfully'))

    /// deploy contract by template id and arguments
    console.log(colors.yellow('deploy contract using template: ') + colors.green(temp))
    await template.deployTemplate(_tid, args, gas, privateKey).then(res => {
        _address = res[0];
    });

    /// make sure the contract instance is deployed successfully by checking its template information
    await checkAddress(_address)
    console.log(colors.yellow('contract deployed successfully: ') + _address)

    /// invoke functions in the contract
    console.log(colors.yellow('create asset and mint: ') + colors.green(1000000000))
    await call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey).then(res=>{
        _tid = res;
    })    

    await checkTx(_tid)
    await call.call(_address, 'assettype',[], gas, value, type, privateKey).then(res =>{
        _type = intTo24Hex(res);
        console.log(colors.yellow('asset created successfully with assettype: ') + colors.green(intTo24Hex(res)))
    });
    
    console.log(colors.yellow('mint asset: ') + colors.green(1000000000))
    await call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey).then(res => {
        _tid = res;
    })

    await checkTx(_tid)
    console.log(colors.yellow('asset minted successfully'))

    await call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 2000000000);
    })

    await call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res =>{
        assert.equal(res, 2000000000);
    })


    console.log(colors.yellow('transfer asset to: ') + colors.green(address))
    await call.call(_address, 'transfer(address,uint256)', [address ,1000000000], gas, value, type, privateKey).then(res => {
        _tid = res;
    })


    await checkTx(_tid)
    console.log(colors.yellow('asset transferred successfully'))

    await call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1000000000);
    })

    await call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res => { 
        assert.equal(res, 2000000000);
    })    
    

    console.log(colors.yellow('burn asset: ') + 500000000)
    await call.call(_address, 'burn', [], gas, 500000000, _type, privateKey).then( res => {
        _tid = res;
    })

    await checkTx(_tid)
    console.log(colors.yellow('asset burned successfully'))

    await call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1000000000);
    })    

    await call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1500000000);
    })
}

testTutorial();








