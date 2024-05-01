// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity 0.8.20;

/**
 * @notice SIP5EventsAndErrors contains errors and events
 *         related to zone interaction as specified in the SIP-5.
 */
interface SIP5EventsAndErrors {
    /**
     * @dev An event that is emitted when a SIP-5 compatible contract is deployed.
     */
    event SeaportCompatibleContractDeployed();
}
