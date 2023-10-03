// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IChildERC20Bridge {
    function onMessageReceive(string calldata sourceChain, string calldata sourceAddress, bytes calldata data) external;
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
