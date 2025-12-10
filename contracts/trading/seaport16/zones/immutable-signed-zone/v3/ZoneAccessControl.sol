// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.20;

import {AccessControl} from "openzeppelin-contracts-5.0.2/access/AccessControl.sol";
import {IAccessControl} from "openzeppelin-contracts-5.0.2/access/IAccessControl.sol";
import {AccessControlEnumerable} from "openzeppelin-contracts-5.0.2/access/extensions/AccessControlEnumerable.sol";
import {ZoneAccessControlEventsAndErrors} from "./interfaces/ZoneAccessControlEventsAndErrors.sol";

/**
 * @notice ZoneAccessControl encapsulates access control functionality for the zone.
 */
abstract contract ZoneAccessControl is AccessControlEnumerable, ZoneAccessControlEventsAndErrors {
    /// @dev Zone manager manages the zone.
    // forge-lint: disable-next-line(unsafe-typecast)
    bytes32 public constant ZONE_MANAGER_ROLE = bytes32("ZONE_MANAGER");

    /**
     * @notice Constructor to setup initial default admin.
     *
     * @param owner The address to assign the DEFAULT_ADMIN_ROLE.
     */
    constructor(address owner) {
        require(owner != address(0), "ZoneAccessControl: owner is the zero address");
        // Grant admin role to the specified owner.
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /**
     * @inheritdoc AccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) public override(AccessControl, IAccessControl) onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE && super.getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 1) {
            revert LastDefaultAdminRole(account);
        }

        super.revokeRole(role, account);
    }

    /**
     * @inheritdoc AccessControl
     */
    function renounceRole(bytes32 role, address callerConfirmation) public override(AccessControl, IAccessControl) {
        if (role == DEFAULT_ADMIN_ROLE && super.getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 1) {
            revert LastDefaultAdminRole(callerConfirmation);
        }

        super.renounceRole(role, callerConfirmation);
    }
}
