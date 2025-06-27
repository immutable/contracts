// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {IStakeHolder} from "./IStakeHolder.sol";

/**
 * @title IStakeHolderV2: Interface for V2 staking system.
 */
interface IStakeHolderV2 is IStakeHolder {
   /// @notice Event summarising a distribution via the stakeFor function. 
    /// @dev There will be one StakeAdded event for each recipient.
    event StakedFor(address _distributor, uint256 _totalDistribution, uint256 _numRecipients);

    /**
     * @notice Stake on behalf of others.
     * @dev Only callable by accounts with DISTRIBUTE_ROLE.
     * @dev Unlike the distributeRewards function, there is no requirement that recipients are existing stakers.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function stakeFor(AccountAmount[] calldata _recipientsAndAmounts) external payable;
}
