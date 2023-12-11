// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;


/**
 * @title ILatestWalletImplLocator
 * @notice Interface for using the latest wallet implementation locator contract.
 */
interface ILatestWalletImplLocator {
    /**
     * Return the address of the latest wallet implementation contract.
     */
    function latestWalletImplementation() external returns (address);
}