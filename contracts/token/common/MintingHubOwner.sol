// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

// solhint-disable no-unused-import
import {HubOwner, AccessControlEnumerable, AccessControl, IAccessControl} from "./HubOwner.sol";

abstract contract MintingHubOwner is HubOwner {
    /// @notice Role to mint tokens
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /**
     * @param _roleAdmin The account that administers other roles and other
     *                   accounts with DEFAULT_ADMIN_ROLE.
     * @param _hubOwner The account associated with Immutable Hub.
     * @param _minterAdmin An account with minter role.
     */
    constructor(address _roleAdmin, address _hubOwner, address _minterAdmin) HubOwner(_roleAdmin, _hubOwner) {
        _grantRole(MINTER_ROLE, _minterAdmin);
    }
}
