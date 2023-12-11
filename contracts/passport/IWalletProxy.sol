// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

/**
 * Interface that WalletProxy.yul implements.
 */
interface IWalletProxy {
    /// @dev Retrieve current implementation contract used by proxy
    function PROXY_getImplementation() external view returns (address implementation);
}