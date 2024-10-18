// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable, IAccessControlUpgradeable, AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";

/// @notice Struct to combine an account and an amount.
struct AccountAmount {
    address account;
    uint256 amount;
}

/**
 * @title StakeHolder: allows anyone to stake any amount of native IMX and to then remove all or part of that stake.
 * @dev The StakeHolder contract is designed to be upgradeable.
 */
contract StakeHolder is AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    /// @notice Error: Attempting to upgrade contract storage to version 0.
    error CanNotUpgradeToV0(uint256 _storageVersion);

    /// @notice Error: Attempting to renounce the last role admin / default admin.
    error MustHaveOneRoleAdmin();

    /// @notice Error: Attempting to stake with zero value.
    error MustStakeMoreThanZero();

    /// @notice Error: Attempting to distribute zero value.
    error MustDistributeMoreThanZero();

    /// @notice Error: Attempting to unstake amount greater than the balance.
    error UnstakeAmountExceedsBalance(uint256 _amountToUnstake, uint256 _currentStake);

    /// @notice Error: The sum of all amounts to distribute did not equal msg.value of the distribute transaction.
    error DistributionAmountsDoNotMatchTotal(uint256 _msgValue, uint256 _calculatedTotalDistribution);

    /// @notice Error: Distributions can only be made to accounts that have staked.
    error AttemptToDistributeToNewAccount(address _account, uint256 _amount);

    /// @notice Event when an amount has been staked or when an amount is distributed to an account.
    event StakeAdded(address _staker, uint256 _amountAdded, uint256 _newBalance);

    /// @notice Event when an amount has been unstaked.
    event StakeRemoved(address _staker, uint256 _amountRemoved, uint256 _newBalance);

    /// @notice Event summarising a distribution. There will also be one StakeAdded event for each recipient.
    event Distributed(address _distributor, uint256 _totalDistribution, uint256 _numRecipients);

    /// @notice Only UPGRADE_ROLE can upgrade the contract
    bytes32 public constant UPGRADE_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Version 0 version number
    uint256 private constant _VERSION0 = 0;

    /// @notice Holds staking information for a single staker.
    struct StakeInfo {
        /// @notice Amount of stake.
        uint256 stake;  
        /// @notice True if this account has ever staked.
        bool hasStaked; 
    }

    /// @notice The amount of value owned by each staker
    // solhint-disable-next-line private-vars-leading-underscore
    mapping(address staker => StakeInfo stakeInfo) private balances;

    /// @notice A list of all stakers who have ever staked.
    /// @dev The list make contain stakers who have completely unstaked (that is, have 
    ///    a balance of 0). This array is never re-ordered. As such, off-chain services
    ///    could cache the results of getStakers().
    // solhint-disable-next-line private-vars-leading-underscore
    address[] private stakers;

    /// @notice version number of the storage variable layout.
    uint256 public version;

    /**
     * @notice Initialises the upgradeable contract, setting up admin accounts.
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     */
    function initialize(address _roleAdmin, address _upgradeAdmin) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(UPGRADE_ROLE, _upgradeAdmin);
        version = _VERSION0;
    }

    /**
     * @notice Function to be called when upgrading this contract.
     * @dev Call this function as part of upgradeToAndCall().
     *      This initial version of this function reverts. There is no situation 
     *      in which it makes sense to upgrade to the V0 storage layout.
     *      Note that this function is permissionless. Future versions must 
     *      compare the code version and the storage version and upgrade 
     *      appropriately. As such, the code will revert if an attacker calls 
     *      this function attempting a malicious upgrade.
     * @ param _data ABI encoded data to be used as part of the contract storage upgrade.
     */
    function upgradeStorage(bytes memory /* _data */) external virtual {
        revert CanNotUpgradeToV0(version);
    }

    /**
     * @notice Renounce a role assigned to msg.sender.
     * @dev Prevents the last default admin role from renouncing the role.
     * @param _role The role to be renounced.
     * @param _account Must equal msg.sender. Used as an additional check.
     */
    function renounceRole(bytes32 _role, address _account) public override(IAccessControlUpgradeable, AccessControlUpgradeable) {
        if (_role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(_role) == 1) {
            revert MustHaveOneRoleAdmin();
        }
        super.renounceRole(_role, _account);
    }

    /**
     * @notice Allow any account to stake more value.
     * @dev The amount being staked is the value of msg.value.
     * @dev This function does not need re-entrancy guard as the add stake
     *  mechanism does not call out to any external function.
     */
    function stake() external payable {
        if (msg.value == 0) {
            revert MustStakeMoreThanZero();
        }
        _addStake(msg.sender, msg.value, false);
    }

    /**
     * @notice Allow any account to remove some or all of their own stake.
     * @dev This function does not need re-entrancy guard as the state is updated
     *  prior to the call to the user's wallet.
     * @param _amountToUnstake Amount of stake to remove.
     */
    function unstake(uint256 _amountToUnstake) external {
        StakeInfo storage stakeInfo = balances[msg.sender];
        uint256 currentStake = stakeInfo.stake;
        if (currentStake < _amountToUnstake) {
            revert UnstakeAmountExceedsBalance(_amountToUnstake, currentStake);
        }
        uint256 newBalance = currentStake - _amountToUnstake;
        stakeInfo.stake = newBalance;

        payable(msg.sender).transfer(_amountToUnstake);

        emit StakeRemoved(msg.sender, _amountToUnstake, newBalance);
    }

    /**
     * @notice Any account can distribute tokens to any set of accounts.
     * @dev The total amount to distribute must match msg.value.
     *  This function does not need re-entrancy guard as the distribution mechanism 
     *  does not call out to another contract.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and 
     *          amounts to be distributed to each recipient.
     */
    function distributeRewards(AccountAmount[] calldata _recipientsAndAmounts)
        external
        payable
    {
        // Initial validity checks
        if (msg.value == 0) {
            revert MustDistributeMoreThanZero();
        }
        uint256 len = _recipientsAndAmounts.length;

        // Distribute the value.
        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            AccountAmount calldata accountAmount = _recipientsAndAmounts[i];
            uint256 amount = accountAmount.amount;
            // Add stake, but require the acount to either currently be staking or have
            // previously staked. 
            _addStake(accountAmount.account, amount, true);
            total += amount;
        }

        // Check that the total distributed matches the msg.value.
        if (total != msg.value) {
            revert DistributionAmountsDoNotMatchTotal(msg.value, total);
        }
        emit Distributed(msg.sender, msg.value, len);
    }

    /**
     * @notice Get the balance of an account.
     * @param _account The account to return the balance for.
     * @return _balance The balance of the account.
     */
    function getBalance(address _account) external view returns (uint256 _balance) {
        return balances[_account].stake;
    }

    /**
     * @notice Determine if an account has ever staked.
     * @param _account The account to determine if they have staked
     * @return _everStaked True if the account has ever staked.
     */
    function hasStaked(address _account) external view returns (bool _everStaked) {
        return balances[_account].hasStaked;
    }

    /**
     * @notice Get the length of the stakers array.
     * @dev This will be equal to the number of staker accounts that have ever staked. 
     *  Some of the accounts might have a zero balance, having staked and then
     *  unstaked. 
     * @return _len The length of the stakers array.
     */
    function getNumStakers() external view returns (uint256 _len) {
        return stakers.length;
    }

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
    function getStakers(uint256 _startOffset, uint256 _numberToReturn)
        external
        view
        returns (address[] memory _stakers)
    {
        address[] memory stakerPartialArray = new address[](_numberToReturn);
        for (uint256 i = 0; i < _numberToReturn; i++) {
            stakerPartialArray[i] = stakers[_startOffset + i];
        }
        return stakerPartialArray;
    }

    /**
     * @notice Add more stake to an account.
     * @dev If the account has a zero balance prior to this call, add the account to the stakers array.
     * @param _account Account to add stake to.
     * @param _amount The amount of stake to add.
     * @param _existingAccountsOnly If true, revert if the account has never been used.
     */
    function _addStake(address _account, uint256 _amount, bool _existingAccountsOnly) private {
        StakeInfo storage stakeInfo = balances[_account];
        uint256 currentStake = stakeInfo.stake;
        if (!stakeInfo.hasStaked) {
            if (_existingAccountsOnly) {
                revert AttemptToDistributeToNewAccount(_account, _amount);
            }
            stakers.push(_account);
            stakeInfo.hasStaked = true;
        }
        uint256 newBalance = currentStake + _amount;
        stakeInfo.stake = newBalance;
        emit StakeAdded(_account, _amount, newBalance);
    }

    // Override the _authorizeUpgrade function
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADE_ROLE) {}

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[20] private __StakeHolderGap;
    // slither-disable-end unused-state
}
