// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/security/ReentrancyGuardUpgradeable.sol";

/// @notice Struct to combine an account and an amount.
struct AccountAmount {
    address account;
    uint256 amount;
}

/**
 * @title StakeHolderERC20: allows anyone to stake any amount of an ERC20 token and to then remove all or part of that stake.
 * @dev The StakeHolderERC20 contract is designed to be upgradeable.
 */
contract StakeHolderERC20 is AccessControlEnumerableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    /// @notice Event when an amount has been staked or when an amount is distributed to an account.
    event StakeAdded(address _staker, uint256 _amountAdded, uint256 _newBalance);

    /// @notice Event when an amount has been unstaked.
    event StakeRemoved(address _staker, uint256 _amountRemoved, uint256 _newBalance);

    /// @notice Event summarising a distribution. There will also be one StakeAdded event for each recipient.
    event Distributed(address _distributor, uint256 _totalDistribution, uint256 _numRecipients);

    /// @notice Only UPGRADE_ROLE can upgrade the contract
    bytes32 public constant UPGRADE_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Only DISTRIBUTE_ROLE can call the distribute function
    bytes32 public constant DISTRIBUTE_ROLE = bytes32("DISTRIBUTE_ROLE");

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

    /// @notice The token used for staking.
    IERC20Upgradeable public token;

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
     * @param _distributeAdmin the address to grant `DISTRIBUTE_ROLE` to
     */
    function initialize(
        address _roleAdmin,
        address _upgradeAdmin,
        address _distributeAdmin,
        address _token
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(UPGRADE_ROLE, _upgradeAdmin);
        _grantRole(DISTRIBUTE_ROLE, _distributeAdmin);
        token = IERC20Upgradeable(_token);
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
        revert CanNotUpgradeToLowerOrSameVersion(version);
    }

    /**
     * @notice Allow any account to stake more value.
     * @param _amount The amount of tokens to be staked.
     */
    function stake(uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert MustStakeMoreThanZero();
        }
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _addStake(msg.sender, _amount, false);
    }

    /**
     * @notice Allow any account to remove some or all of their own stake.
     * @param _amountToUnstake Amount of stake to remove.
     */
    function unstake(uint256 _amountToUnstake) external nonReentrant {
        StakeInfo storage stakeInfo = balances[msg.sender];
        uint256 currentStake = stakeInfo.stake;
        if (currentStake < _amountToUnstake) {
            revert UnstakeAmountExceedsBalance(_amountToUnstake, currentStake);
        }
        uint256 newBalance = currentStake - _amountToUnstake;
        stakeInfo.stake = newBalance;

        emit StakeRemoved(msg.sender, _amountToUnstake, newBalance);

        token.safeTransfer(msg.sender, _amountToUnstake);
    }

    /**
     * @notice Accounts with DISTRIBUTE_ROLE can distribute tokens to any set of accounts.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function distributeRewards(
        AccountAmount[] calldata _recipientsAndAmounts
    ) external nonReentrant onlyRole(DISTRIBUTE_ROLE) {
        // Initial validity checks
        uint256 len = _recipientsAndAmounts.length;
        if (len == 0) {
            revert MustDistributeMoreThanZero();
        }

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
        token.safeTransferFrom(msg.sender, address(this), total);
        emit Distributed(msg.sender, total, len);
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
    function getStakers(
        uint256 _startOffset,
        uint256 _numberToReturn
    ) external view returns (address[] memory _stakers) {
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

    /**
     * @notice Prevent revoke or renounce role for the last DEFAULT_ADMIN_ROLE / the last role admin.
     * @param _role The role to be renounced.
     * @param _account Account to be revoked.
     */
    function _revokeRole(bytes32 _role, address _account) internal override {
        if (_role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(_role) == 1) {
            revert MustHaveOneRoleAdmin();
        }
        super._revokeRole(_role, _account);
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderERC20Gap;
    // slither-disable-end unused-state
}
