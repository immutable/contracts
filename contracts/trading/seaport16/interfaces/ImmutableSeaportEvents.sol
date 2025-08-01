// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2
// solhint-disable compiler-version
pragma solidity ^0.8.17;

/**
 * @notice ImmutableSeaportEvents contains events
 *         related to the ImmutableSeaport contract
 */
interface ImmutableSeaportEvents {
    /**
     * @dev Emit an event when an allowed zone status is updated
     */
    event AllowedZoneSet(address zoneAddress, bool allowed);
}
