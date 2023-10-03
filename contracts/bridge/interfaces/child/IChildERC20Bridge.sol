// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IChildERC20Bridge {
    /**
     * @notice Receives a bridge message from root chain, parsing the message type then executing.
     * @param sourceChain The chain the message originated from.
     * @param sourceAddress The address the message originated from.
     * @param data The data payload of the message.
     */
    function onMessageReceive(string calldata sourceChain, string calldata sourceAddress, bytes calldata data) external;
    
    /**
     * @notice Sets a new bridge adaptor address to receive and send function calls for L1 messages
     * @param newBridgeAdaptor The new child chain bridge adaptor address.
     */
    function updateBridgeAdaptor(address newBridgeAdaptor) external;
}

interface IChildERC20BridgeEvents {
    event L2TokenMapped(address rootToken, address childToken);
}

interface IChildERC20BridgeErrors {
    error ZeroAddress();
    error AlreadyMapped();
    error NotBridgeAdaptor();
    error InvalidData();
    error InvalidSourceChain();
    error InvalidSourceAddress();
    error InvalidRootChain();
    error InvalidRootERC20BridgeAdaptor();
}
