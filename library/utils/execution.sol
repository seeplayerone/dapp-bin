pragma solidity 0.4.25;

contract Execution {
    function execute(address target, bytes4 selector) public returns (bool){
        return target.call(abi.encodePacked(selector));        
    }

    function execute(address target, string signature) public returns (bool){
        bytes4 selector = bytes4(keccak256(abi.encodePacked(signature)));
        return target.call(abi.encodePacked(selector));        
    }

    function execute(address target, bytes4 selector, bytes params) public returns (bool){
        return target.call(abi.encodePacked(selector, params));        
    }

    function execute(address target, string signature, bytes params) public returns (bool){
        bytes4 selector = bytes4(keccak256(abi.encodePacked(signature)));
        return target.call(abi.encodePacked(selector, params));        
    }

    function execute(address target, string signature, uint amount, uint assettype) public returns (bool){
        bytes4 selector = bytes4(keccak256(abi.encodePacked(signature)));
        return target.call.value(amount, assettype)(abi.encodePacked(selector));        
    }

    function execute(address target, bytes4 selector, uint amount, uint assettype) public returns (bool){
        return target.call.value(amount, assettype)(abi.encodePacked(selector));        
    }

    function execute(address target, string signature, bytes params, uint amount, uint assettype) public returns (bool){
        bytes4 selector = bytes4(keccak256(abi.encodePacked(signature)));
        return target.call.value(amount, assettype)(abi.encodePacked(selector, params));        
    }

    function execute(address target, bytes4 selector, bytes params, uint amount, uint assettype) public returns (bool){
        return target.call.value(amount, assettype)(abi.encodePacked(selector, params));        
    }
}