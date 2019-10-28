rpc = require("@asimovdev/asimov-cli/scripts/rpc")
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

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

function intTo24Hex(value) {
    var str = parseInt(value, 10).toString(16);
    while(str.length < 24){
        str = "0" + str;
    }
    return str;
}

var temp = "template_" + Date.now();
var name = [];
name.push(temp);

async function testTutorial() {
    var _tid;
    var _address;
    var _type;

    console.log(colors.yellow('create template: ') + colors.green(temp))
    template.createTemplateWithContractName(source, temp, category, gas, privateKey, "Tutorial").then(res => {
        console.log(colors.yellow('template created successfully: ') + colors.green(res))
        _tid = res;
    });

    await sleep(12000);
    console.log(colors.yellow('deploy contract using template: ') + colors.green(temp))
    template.deployTemplate(_tid, name, gas, privateKey).then(res => {
        console.log(colors.yellow('contract deployed successfully: ') + colors.green(res[0]))
        _address = res[0];
    });

    await sleep(12000);
    console.log(colors.yellow('create asset and mint: ') + colors.green(1000000000))
    call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey);

    await sleep(12000);
    call.call(_address, 'assettype',[], gas, value, type, privateKey).then(res =>{
        console.log(colors.yellow('asset created successfully with assettype: ') + colors.green(intTo24Hex(res)))
        _type = intTo24Hex(res);
    });

    await sleep(2000);
    console.log(colors.yellow('mint asset: ') + colors.green(1000000000))
    call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey).then(res => {
        console.log(colors.yellow('asset minted successfully'))
    })

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 2000000000);
    })

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res =>{
        assert.equal(res, 2000000000);
    })

    await sleep(2000);
    console.log(colors.yellow('transfer asset to: ') + colors.green(address))
    call.call(_address, 'transfer(address,uint256)', [address ,1000000000], gas, value, type, privateKey).then(res => {
        console.log(colors.yellow('asset transferred successfully'))
    })

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1000000000);
    })

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res => { 
        assert.equal(res, 2000000000);
    })


    await sleep(2000);
    call.call(_address, 'burn', [], gas, 500000000, _type, privateKey);

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1000000000);
    })

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey).then(res => {
        assert.equal(res, 1500000000);
    })
}

testTutorial();








