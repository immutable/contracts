// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IStakeHolder, StakeHolderBase} from "./StakeHolderBase.sol";
import {IWIMX} from "./IWIMX.sol";

/**
 * @title StakeHolderWIMX: allows anyone to stake any amount of IMX and to then remove all or part of that stake.
 * @dev Stake can be added and withdrawn either as native IMX only.
 * The StakeHolderWIMX contract is designed to be upgradeable.
 */
contract StakeHolderWIMX is StakeHolderBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Error: Unstake transfer failed.
    error UnstakeTransferFailed();

    /// @notice The token used for staking.
    IWIMX internal wIMX;

    /**
     * @notice Initialises the upgradeable contract, setting up admin accounts.
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     * @param _distributeAdmin the address to grant `DISTRIBUTE_ROLE` to
     * @param _wIMXToken The address of the WIMX contract.
     */
    function initialize(
        address _roleAdmin,
        address _upgradeAdmin,
        address _distributeAdmin,
        address _wIMXToken
    ) public initializer {
        __StakeHolderWIMX_init(_roleAdmin, _upgradeAdmin, _distributeAdmin, _wIMXToken);
    }

    function __StakeHolderWIMX_init(
        address _roleAdmin,
        address _upgradeAdmin,
        address _distributeAdmin,
        address _wIMXToken
    ) internal onlyInitializing {
        __StakeHolderBase_init(_roleAdmin, _upgradeAdmin, _distributeAdmin);
        wIMX = IWIMX(_wIMXToken);
    }

    receive() external payable {
        // Receive IMX sent by the WIMX contract when wIMX.withdraw() is called.
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function getToken() external view returns (address) {
        return address(wIMX);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _sendValue(address _to, uint256 _amount) internal override {
        // Convert WIMX to native IMX
        wIMX.withdraw(_amount);

        // slither-disable-next-line low-level-calls,arbitrary-send-eth
        (bool success, bytes memory returndata) = payable(_to).call{value: _amount}("");
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
     * @inheritdoc StakeHolderBase
     */
    function _checksAndTransfer(uint256 _amount) internal override {
        // Check that the amount matches the msg.value.
        if (_amount != msg.value) {
            revert MismatchMsgValueAmount(msg.value, _amount);
        }

        // Convert native IMX to WIMX.
        wIMX.deposit{value: _amount}();
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderERC20AndNativeGap;
    // slither-disable-end unused-state
}
