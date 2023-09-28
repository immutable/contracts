// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// @dev A contract for ensuring the Axelar Gateway is called correctly during unit tests.
contract MockAxelarGateway {
    function callContract(string memory childChain, string memory childBridgeAdaptor, bytes memory payload) external {}
}
