// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2
pragma solidity 0.8.17;

/**
 * @notice SIP6EventsAndErrors contains errors and events
 *         related to zone interaction as specified in the SIP6.
 */
interface SIP6EventsAndErrors {
    /**
     * @dev Revert with an error if SIP6 version is not supported
     */
    error UnsupportedExtraDataVersion(uint8 version);
}
