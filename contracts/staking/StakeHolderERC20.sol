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
     * @inheritdoc IStakeHolder
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _sendValue(address _to, uint256 _amount) internal override {
        token.safeTransfer(_to, _amount);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _checksAndTransfer(uint256 _amount) internal override {
        if (msg.value != 0) {
            revert NonPayable();
        }
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderERC20Gap;
    // slither-disable-end unused-state
}
