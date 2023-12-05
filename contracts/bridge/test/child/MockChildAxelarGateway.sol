// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MockChildAxelarGateway {
    function validateContractCall(
        bytes32 ,
        string calldata ,
        string calldata ,
        bytes32 
    ) external pure returns (bool) {
        return true;
    }
}
