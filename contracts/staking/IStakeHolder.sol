// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {IAccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/IAccessControlEnumerableUpgradeable.sol";

/**
 * @title IStakeHolder: Interface for staking system.
 */
interface IStakeHolder is IAccessControlEnumerableUpgradeable {
    /// @notice implementation does not accept native tokens.
    error NonPayable();

    /// @notice Error: Attempting to upgrade contract storage to version 0.
    error CanNotUpgradeToLowerOrSameVersion(uint256 _storageVersion);

    /// @notice Error: Attempting to renounce the last role admin / default admin.
    error MustHaveOneRoleAdmin();

    /// @notice Error: Attempting to stake with zero value.
    error MustStakeMoreThanZero();

    /// @notice Error: Attempting to distribute zero value.
    error MustDistributeMoreThanZero();

    /// @notice Error: Attempting to unstake amount greater than the balance.
    error UnstakeAmountExceedsBalance(uint256 _amountToUnstake, uint256 _currentStake);

    /// @notice Error: Distributions can only be made to accounts that have staked.
    error AttemptToDistributeToNewAccount(address _account, uint256 _amount);

    /// @notice Error: Call to stake for implementations that accept value require value and parameter to match.
    error MismatchMsgValueAmount(uint256 _msgValue, uint256 _amount);

    /// @notice Error: Unstake native value transfer failed with revert with no revert information.
    /// @dev An error was detected by the EVM. For example a function call to an address with no contract associated with it.
    error UnstakeTransferFailed();

    /// @notice Native IMX was received from an account other than the WIMX contract.
    error ImxNotFromWimxContract(address _from);

    /// @notice Event when an amount has been staked or when an amount is distributed to an account.
    event StakeAdded(address _staker, uint256 _amountAdded, uint256 _newBalance);

    /// @notice Event when an amount has been unstaked.
    event StakeRemoved(address _staker, uint256 _amountRemoved, uint256 _newBalance);

    /// @notice Event summarising a distribution.
    /// @dev There will also be one StakeAdded event for each recipient.
    event Distributed(address _distributor, uint256 _totalDistribution, uint256 _numRecipients);

    /// @notice Event summarising a distribution via the stakeFor function.
    /// @dev There will be one StakeAdded event for each recipient.
    event StakedFor(address _distributor, uint256 _totalDistribution, uint256 _numRecipients);

    /// @notice Struct to combine an account and an amount.
    struct AccountAmount {
        address account;
        uint256 amount;
    }

    /**
     * @notice Allow any account to stake more value.
     * @param _amount The amount of tokens to be staked.
     */
    function stake(uint256 _amount) external payable;

    /**
     * @notice Allow any account to remove some or all of their own stake.
     * @param _amountToUnstake Amount of stake to remove.
     */
    function unstake(uint256 _amountToUnstake) external;

    /**
     * @notice Distribute rewards to stakers.
     * @dev Only callable by accounts with DISTRIBUTE_ROLE.
     * @dev Recipients must have staked value prior to this function call.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function distributeRewards(AccountAmount[] calldata _recipientsAndAmounts) external payable;

    /**
     * @notice Stake on behalf of others.
     * @dev Only callable by accounts with DISTRIBUTE_ROLE.
     * @dev Unlike the distributeRewards function, there is no requirement that recipients are existing stakers.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function stakeFor(AccountAmount[] calldata _recipientsAndAmounts) external payable;

    /**
     * @notice Get the balance of an account.
     * @param _account The account to return the balance for.
     * @return _balance The balance of the account.
     */
    function getBalance(address _account) external view returns (uint256 _balance);

    /**
     * @notice Determine if an account has ever staked.
     * @param _account The account to determine if they have staked
     * @return _everStaked True if the account has ever staked.
     */
    function hasStaked(address _account) external view returns (bool _everStaked);

    /**
     * @notice Get the length of the stakers array.
     * @dev This will be equal to the number of staker accounts that have ever staked.
     *  Some of the accounts might have a zero balance, having staked and then
     *  unstaked.
     * @return _len The length of the stakers array.
     */
    function getNumStakers() external view returns (uint256 _len);

    /**
     * @notice Get the staker accounts from the stakers array.
     * @dev Given the stakers list could grow arbitrarily long. To prevent out of memory or out of
     *  gas situations due to attempting to return a very large array, this function call specifies
     *  the start offset and number of accounts to be return.
     *  NOTE: This code will cause a panic if the start offset + number to return is greater than
     *  the length of the array. Use getNumStakers before calling this function to determine the
     *  length of the array.
     * @param _startOffset First offset in the stakers array to return the account number for.
     * @param _numberToReturn The number of accounts to return.
     * @return _stakers A subset of the stakers array.
     */
    function getStakers(
        uint256 _startOffset,
        uint256 _numberToReturn
    ) external view returns (address[] memory _stakers);

    /**
     * @return The address of the staking token.
     */
    function getToken() external view returns (address);

    /**
     * @notice version number of the storage variable layout.
     */
    function version() external view returns (uint256);

    /**
     * @notice Only UPGRADE_ROLE can upgrade the contract
     */
    function UPGRADE_ROLE() external pure returns (bytes32);

    /**
     * @notice Only DISTRIBUTE_ROLE can call the distribute function
     */
    function DISTRIBUTE_ROLE() external pure returns (bytes32);
}

