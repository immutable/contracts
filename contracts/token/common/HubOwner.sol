// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlEnumerable, AccessControl, IAccessControl} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @notice Adds the concept of a hub owner.
 * @dev This contract has the concept of a hubOwner, called _hubOwner in the constructor.
 *  This account has no rights to execute any administrative actions within the contract,
 *  with the exception of renouncing their ownership. 
 *  The Immutable Hub uses this function to help associate the ERC 20 contract 
 *  with a specific Immutable Hub account.
 */
abstract contract HubOwner is AccessControlEnumerable {
    // Report an error if renounceRole is called for the last DEFAULT_ADMIN_ROLE or 
    // HUB_OWNER_ROLE.
    error RenounceLastNotAllowed();

    /// @notice Role to indicate hub owner
    bytes32 public constant HUB_OWNER_ROLE = bytes32("HUB_OWNER_ROLE");


    /**
     * @param _roleAdmin The account that administers other roles and other 
     *                   accounts with DEFAULT_ADMIN_ROLE.
     * @param _hubOwner The account associated with Immutable Hub. 
     */
    constructor(address _roleAdmin, address _hubOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(HUB_OWNER_ROLE, _hubOwner);
    }

    /**
     * @dev Renounces the role `role` from the calling account. Prevents the last hub owner and admin from 
     * renouncing their role.
     * @param role The role to renounce.
     * @param account The account to renounce the role from.
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        if ((role == HUB_OWNER_ROLE || role == DEFAULT_ADMIN_ROLE) && (getRoleMemberCount(role) == 1)) {
            revert RenounceLastNotAllowed();
        }
        super.renounceRole(role, account);
    }

    /** 
     * @notice Returns the addresses which have a certain role.
     * @dev In the unlikely event that there are many accounts with a certain role,
     *      this function might cause out of memory issues, and fail. 
     * @param _role Role to return array of admins for.
     * @return admins The array of admins with the requested role.
     */
    function getAdmins(bytes32 _role) public view returns (address[] memory admins) {
        uint256 adminCount = getRoleMemberCount(_role);
        admins = new address[](adminCount);
        for (uint256 i; i < adminCount; i++) {
            admins[i] = getRoleMember(_role, i);
        }
        return admins;
    }
}
