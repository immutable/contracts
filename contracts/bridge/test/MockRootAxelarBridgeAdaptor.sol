// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// @dev A contract for ensuring the Axelar Bridge Adaptor is called correctly during unit tests.
contract MockRootAxelarBridgeAdaptor {
    function mapToken(
        address rootToken,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external payable {}
}
