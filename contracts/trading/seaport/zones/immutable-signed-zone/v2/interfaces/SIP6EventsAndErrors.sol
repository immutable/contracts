// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

/**
 * @notice SIP6EventsAndErrors contains errors and events
 *         related to zone interaction as specified in the SIP-6.
 */
// This contract name re-use is OK because the SIP6EventsAndErrors is an interface and not a deployable contract.
// slither-disable-next-line name-reused
interface SIP6EventsAndErrors {
    /**
     * @dev Revert with an error if SIP-6 version byte is not supported.
     */
    error UnsupportedExtraDataVersion(uint8 version);
}
