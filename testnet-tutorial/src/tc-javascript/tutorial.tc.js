template = require("@asimovdev/asimov-cli/scripts/template")
call = require("@asimovdev/asimov-cli/scripts/call")
rpc = require("@asimovdev/asimov-cli/scripts/rpc")

var source = '/Users/xxd/gitflow/dapp-contracts/dapp-bin/testnet-tutorial/src/contracts/tutorial.sol';
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

    template.createTemplateWithContractName(source, temp, category, gas, privateKey, "Tutorial").then(res => {
        _tid = res;
    });

    await sleep(12000);
    template.deployTemplate(_tid, name, gas, privateKey).then(res => {
        _address = res[0];
    });

    await sleep(12000);
    call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey);

    await sleep(12000);
    call.call(_address, 'assettype',[], gas, value, type, privateKey).then(res =>{
        _type = intTo24Hex(res);
        console.log(_type);
    });

    await sleep(2000);
    call.call(_address, 'mint(uint256)', [1000000000], gas, value, type, privateKey);

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey);

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey);

    await sleep(2000);
    call.call(_address, 'transfer(address,uint256)', [address ,1000000000], gas, value, type, privateKey);

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey);

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey);

    await sleep(2000);
    call.call(_address, 'burn', [], gas, 500000000, _type, privateKey);

    await sleep(12000);
    call.call(_address, 'checkBalance', [], gas, value, type, privateKey);

    await sleep(2000);
    call.call(_address, 'checkTotalSupply', [], gas, value, type, privateKey);
}

testTutorial();








