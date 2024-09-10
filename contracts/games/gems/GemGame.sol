// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
// solhint-disable not-rely-on-time

pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

error Unauthorized();
error ContractPaused();

/**
 * @title GemGame - A simple contract that emits an event for the purpose of indexing off-chain
 * @author Immutable
 * @dev The GemGame contract is not designed to be upgradeable or extended
 */
contract GemGame is AccessControl, Pausable {
    /// @notice Indicates that an account has earned a gem
    event GemEarned(address indexed account, uint256 timestamp);

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
    constructor(address _admin, address _pauser, address _unpauser) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(_PAUSE, _pauser);
        _grantRole(_UNPAUSE, _unpauser);
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
     * @notice Function that emits a `GemEarned` event
     */
    function earnGem() external {
        if (paused()) revert ContractPaused();
        emit GemEarned(msg.sender, block.timestamp);
    }
}
