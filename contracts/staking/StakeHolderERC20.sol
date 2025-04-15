// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

// import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
// import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IStakeHolder, StakeHolderBase} from "./StakeHolderBase.sol";

/**
 * @title StakeHolderERC20: allows anyone to stake any amount of an ERC20 token and to then remove all or part of that stake.
 * @dev The StakeHolderERC20 contract is designed to be upgradeable.
 */
contract StakeHolderERC20 is StakeHolderBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The token used for staking.
    IERC20Upgradeable internal token;

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
        __StakeHolderBase_init(_roleAdmin, _upgradeAdmin, _distributeAdmin);
        token = IERC20Upgradeable(_token);
    }

    /**
     * @notice Allow any account to stake more value.
     * @param _amount The amount of tokens to be staked.
     */
    function stake(uint256 _amount) external payable nonReentrant {
        if (msg.value != 0) {
            revert NonPayable();
        }
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

        emit StakeRemoved(msg.sender, _amountToUnstake, newBalance, block.timestamp);

        token.safeTransfer(msg.sender, _amountToUnstake);
    }

    /**
     * @notice Accounts with DISTRIBUTE_ROLE can distribute tokens to any set of accounts.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function distributeRewards(
        AccountAmount[] calldata _recipientsAndAmounts
    ) external payable nonReentrant onlyRole(DISTRIBUTE_ROLE) {
        if (msg.value != 0) {
            revert NonPayable();
        }

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
        if (total == 0) {
            revert MustDistributeMoreThanZero();
        }
        token.safeTransferFrom(msg.sender, address(this), total);
        emit Distributed(msg.sender, total, len);
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function getToken() external view returns(address) {
        return address(token);
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
        emit StakeAdded(_account, _amount, newBalance, block.timestamp);
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderERC20Gap;
    // slither-disable-end unused-state
}
