// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
// solhint-disable not-rely-on-time

pragma solidity ^0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {SessionActivity} from "./SessionActivity.sol";

error Unauthorized();
error NameAlreadyRegistered();

/**
 * @title SessionActivityDeployer - A factory contract that deploys SessionActivity contracts and tracks their addresses and names
 * @author Immutable
 * @dev The SessionActivityDeployer contract is not designed to be upgradeable or extended.
 */
contract SessionActivityDeployer is AccessControlEnumerable {
    /// @notice Indicates that an account has registered session activity
    event SessionActivityDeployed(address indexed account, address indexed deployedContract, string indexed name);

    /// @notice Role to allow deploying SessionActivity contracts
    bytes32 private constant _DEPLOYER_ROLE = keccak256("DEPLOYER");

    /// @notice The address for the pauser role on the SessionActivity contract
    address private _pauser;

    /// @notice The address for the unpauser role on the SessionActivity contract
    address private _unpauser;

    /**
     *   @notice Sets the DEFAULT_ADMIN, PAUSE and UNPAUSE roles
     *   @param admin The address for the admin role
     *   @param deployer The address for the deployer role
     *   @param pauser The address for the pauser role on the SessionActivity contract
     *   @param unpauser The address for the unpauser role on the SessionActivity contract
     */
    constructor(address admin, address deployer, address pauser, address unpauser) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(_DEPLOYER_ROLE, deployer);
        _pauser = pauser;
        _unpauser = unpauser;
    }

    /**
     *   @notice Deploys a new SessionActivity contract
     *   @param name The name of the SessionActivity contract
     *   @dev Only accounts granted the _DEPLOYER_ROLE can call this function
     */
    function deploy(string memory name) public {
        // Ensure the caller has the deployer role
        if (!hasRole(_DEPLOYER_ROLE, msg.sender)) revert Unauthorized();

        // Get the existing admin role
        address admin = getRoleMember(DEFAULT_ADMIN_ROLE, 0);

        // Deploy the session activity contract
        SessionActivity sessionActivityContract = new SessionActivity(admin, _pauser, _unpauser, name);
        emit SessionActivityDeployed(msg.sender, address(sessionActivityContract), name);
    }
}
