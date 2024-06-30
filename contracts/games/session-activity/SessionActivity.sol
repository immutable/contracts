// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
// solhint-disable not-rely-on-time

pragma solidity ^0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

error Unauthorized();
error ContractPaused();

/**
 * @title SessionActivity - A simple contract that emits an event for the purpose of recording session activity on-chain
 * @author Immutable
 * @dev The SessionActivity contract is not designed to be upgradeable or extended.
 */
contract SessionActivity is AccessControlEnumerable, Pausable {
    /// @notice Indicates that session activity has been recorded for an account
    event SessionActivityRecorded(address indexed account, uint256 timestamp);

    /// @notice The name of the contract
    string public name;

    /// @notice Role to allow pausing the contract
    bytes32 private constant _PAUSE = keccak256("PAUSE");

    /// @notice Role to allow unpausing the contract
    bytes32 private constant _UNPAUSE = keccak256("UNPAUSE");

    /**
     *   @notice Sets the DEFAULT_ADMIN, PAUSE and UNPAUSE roles
     *   @param _admin The address for the admin role
     *   @param _pauser The address for the pauser role
     *   @param _unpauser The address for the unpauser role
     */
    constructor(address _admin, address _pauser, address _unpauser, string memory _name) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(_PAUSE, _pauser);
        _grantRole(_UNPAUSE, _unpauser);
        name = _name;
    }

    /**
     *   @notice Pauses the contract
     */
    function pause() external {
        if (!hasRole(_PAUSE, msg.sender)) revert Unauthorized();
        _pause();
    }

    /**
     *   @notice Unpauses the contract
     */
    function unpause() external {
        if (!hasRole(_UNPAUSE, msg.sender)) revert Unauthorized();
        _unpause();
    }

    /**
     * @notice Function that emits a `SessionActivityRecorded` event
     */
    function recordSessionActivity() external {
        if (paused()) revert ContractPaused();
        emit SessionActivityRecorded(msg.sender, block.timestamp);
    }
}
