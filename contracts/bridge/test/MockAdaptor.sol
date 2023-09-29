// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// @dev A contract for ensuring the Axelar Bridge Adaptor is called correctly during unit tests.
contract MockAdaptor {
    function sendMessage(bytes calldata , address) external payable{}
}
