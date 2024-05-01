// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity 0.8.20;

/**
 * @notice ZoneAccessControlEventsAndErrors contains errors and events
 *         related to zone access control.
 */
interface ZoneAccessControlEventsAndErrors {
    /**
     * @dev Revert with an error if revoking last DEFAULT_ADMIN_ROLE.
     */
    error LastDefaultAdminRole(address account);
}
