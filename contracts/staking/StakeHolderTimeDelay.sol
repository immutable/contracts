// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";


/**
 * @notice StakeHolder contracts can use this function to enforce a time delay for admin actions.
 * @dev Typically, staking systems would use this contract as the only account with UPGRADE_ROLE 
 *  and DEFAULT_ADMIN_ROLE roles. This ensures any upgrade proposals or proposals to add more
 *  accounts with UPGRADE_ROLE or DISTRIBUTE_ROLE must go through a time delay before being actioned.
 *  A staking system could choose to have no account with DEFAULT_ADMIN_ROLE, thus ensuring no additional
 *  acccounts are granted UPGRADE_ROLE. A staking system could choose to have no account with UPGRADE_ROLE,
 *  or DEFAULT_ADMIN_ROLE thus ensuring the StakeHolder contract can not be upgraded.
 */
contract StakeHolderTimeDelay is TimelockController {
    /// @notice Change the delay is not allowed.
    error UpdateDelayNotAlllowed();


    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     *
     * Pass in address(0) as the optional admin. This means that changes to proposers and 
     * executors use the time delay.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) 
        TimelockController(minDelay, proposers, executors, address(0)) {
    }

    /**
     * @notice Do not allow delay to be changed.
     */
    function updateDelay(uint256 /* newDelay */) external pure override {
        revert UpdateDelayNotAlllowed();
    }
}
