// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {StakeHolderBase} from "./StakeHolderBase.sol";
import {IStakeHolderV2, IStakeHolder} from "./IStakeHolderV2.sol";

/**
 * @title StakeHolderBase: allows anyone to stake any amount of an ERC20 token and to then remove all or part of that stake.
 * @dev This contract is designed to be upgradeable.
 */
abstract contract StakeHolderBaseV2 is IStakeHolderV2, StakeHolderBase {
    /// @notice Version 2 version number
    uint256 internal constant _VERSION2 = 2;


    /**
     * @notice Initialises the upgradeable contract, setting up admin accounts.
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     * @param _distributeAdmin the address to grant `DISTRIBUTE_ROLE` to
     */
    function __StakeHolderBase_init(
        address _roleAdmin,
        address _upgradeAdmin,
        address _distributeAdmin
    ) internal virtual override {
        // NOTE: onlyInitializing is called in super.
        super.__StakeHolderBase_init(_roleAdmin, _upgradeAdmin, _distributeAdmin);
        version = _VERSION2;
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
    function upgradeStorage(bytes memory /* _data */) external virtual override {
        if (version == _VERSION0) {
            // Upgrading from version 0 to 2 involves only code changes and 
            // changing the storage version number.
            version = _VERSION2;
        }
        else {
            // Don't allow downgrade or re-initialising.
            revert CanNotUpgradeToLowerOrSameVersion(version);
        }
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function distributeRewards(
        AccountAmount[] calldata _recipientsAndAmounts
    ) external payable override(IStakeHolder, StakeHolderBase) nonReentrant onlyRole(DISTRIBUTE_ROLE) {
        uint256 total = _distributeRewards(_recipientsAndAmounts, true);
        uint256 len = _recipientsAndAmounts.length;
        emit Distributed(msg.sender, total, len);
    }

    /**
     * @inheritdoc IStakeHolderV2
     */
    function stakeFor(
        AccountAmount[] calldata _recipientsAndAmounts
    ) external payable nonReentrant onlyRole(DISTRIBUTE_ROLE) {
        uint256 total = _distributeRewards(_recipientsAndAmounts, false);
        uint256 len = _recipientsAndAmounts.length;
        emit StakedFor(msg.sender, total, len);
    }

    /**
     * @notice Distribute tokens to a set of accounts.
     * @param _recipientsAndAmounts An array of recipients to distribute value to and
     *          amounts to be distributed to each recipient.
     * @param _existingAccountsOnly If true, revert if the account has never been used.
     * @return _total Value distirbuted.
     */
    function _distributeRewards(
        AccountAmount[] calldata _recipientsAndAmounts,
        bool _existingAccountsOnly
    ) private returns (uint256 _total) {
        // Distribute the value.
        _total = 0;
        uint256 len = _recipientsAndAmounts.length;
        for (uint256 i = 0; i < len; i++) {
            AccountAmount calldata accountAmount = _recipientsAndAmounts[i];
            uint256 amount = accountAmount.amount;
            // Add stake, but require the account to either currently be staking or have
            // previously staked.
            _addStake(accountAmount.account, amount, _existingAccountsOnly);
            _total += amount;
        }
        if (_total == 0) {
            revert MustDistributeMoreThanZero();
        }
        _checksAndTransfer(_total);
    }
}
