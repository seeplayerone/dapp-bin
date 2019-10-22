pragma solidity 0.4.25;

contract Execution {
    function execute(address targetContract, bytes encodedMethodAndParameters) internal {
        require(targetContract.call(encodedMethodAndParameters));
    }

    function executeWithAsset(address targetContract, bytes encodedMethodAndParameters, uint amount, uint96 assetGlobalId) internal {
        require(targetContract.call.value(amount,assetGlobalId)(encodedMethodAndParameters));
    }
}