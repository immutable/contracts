// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

// import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
// import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {IStakeHolder, StakeHolderBase} from "./StakeHolderBase.sol";


/**
 * @title StakeHolder: allows anyone to stake any amount of native IMX and to then remove all or part of that stake.
 * @dev The StakeHolder contract is designed to be upgradeable.
 */
contract StakeHolderNative is StakeHolderBase {
      /// @notice Error: Unstake transfer failed.
    error UnstakeTransferFailed();

    /**
     * @notice Initialises the upgradeable contract, setting up admin accounts.
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     * @param _distributeAdmin the address to grant `DISTRIBUTE_ROLE` to
     */
    function initialize(address _roleAdmin, address _upgradeAdmin, address _distributeAdmin) public initializer {
        __StakeHolderBase_init(_roleAdmin, _upgradeAdmin, _distributeAdmin);
    }

    /**
     * @notice Allow any account to stake more value.
     * @dev The amount being staked is the value of msg.value.
     * @dev This function does not need re-entrancy guard as the add stake
     *  mechanism does not call out to any external function.
     */
    function stake(uint256 _amount) external payable {
        if (msg.value == 0) {
            revert MustStakeMoreThanZero();
        }
        if (_amount != msg.value) {
            revert MismatchMsgValueAmount(msg.value, _amount);
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

        emit StakeRemoved(msg.sender, _amountToUnstake, newBalance, block.timestamp);

        // slither-disable-next-line low-level-calls
        (bool success, bytes memory returndata) = payable(msg.sender).call{value: _amountToUnstake}("");
        if (!success) {
            // Look for revert reason and bubble it up if present.
            // Revert reasons should contain an error selector, which is four bytes long.
            if (returndata.length >= 4) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert UnstakeTransferFailed();
            }
        }
    }

    /**
     * @notice Accounts with DISTRIBUTE_ROLE can distribute tokens to any set of accounts.
     * @dev The total amount to distribute must match msg.value.
     *  This function does not need re-entrancy guard as the distribution mechanism
     *  does not call out to another contract.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     */
    function distributeRewards(
        AccountAmount[] calldata _recipientsAndAmounts
    ) external payable onlyRole(DISTRIBUTE_ROLE) {
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
     * @inheritdoc IStakeHolder
     */
    function getToken() external pure returns(address) {
        return address(0);
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
    uint256[50] private __StakeHolderGap;
    // slither-disable-end unused-state
}
