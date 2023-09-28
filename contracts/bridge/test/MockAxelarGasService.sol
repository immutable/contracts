// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// @dev A contract for ensuring the Axelar gas service is called correctly during unit tests.
contract MockAxelarGasService {
    function payNativeGasForContractCall(
        address sender,
        string calldata,
        string calldata,
        bytes calldata,
        address refundAddress
    ) external payable {}
}
