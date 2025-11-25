// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {IStakeHolder, StakeHolderBase, StakeHolderNative} from "./StakeHolderNative.sol";
import {IWIMX} from "./IWIMX.sol";

/**
 * @title StakeHolderWIMX: allows anyone to stake any amount of IMX and to then remove all or part of that stake.
 * @dev Stake can be added and withdrawn either as native IMX only.
 * @dev The StakeHolderWIMX contract is designed to be upgradeable.
 */
contract StakeHolderWIMX is StakeHolderNative {
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
        __StakeHolderBase_init(_roleAdmin, _upgradeAdmin, _distributeAdmin);
        wIMX = IWIMX(_wIMXToken);
    }

    receive() external payable {
        // Receive IMX sent by the WIMX contract when wIMX.withdraw() is called.
        // Revert if any other account sends IMX to prevent the tokens being stuck in this contract.
        if (msg.sender != address(wIMX)) {
            revert ImxNotFromWimxContract(msg.sender);
        }
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function getToken() external view override returns (address) {
        return address(wIMX);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _sendValue(address _to, uint256 _amount) internal override {
        // Convert WIMX to native IMX
        wIMX.withdraw(_amount);

        super._sendValue(_to, _amount);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _checksAndTransfer(uint256 _amount) internal override {
        super._checksAndTransfer(_amount);

        // Convert native IMX to WIMX.
        // slither-disable-next-line arbitrary-send-eth
        wIMX.deposit{value: _amount}();
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderWIMXGap;
    // slither-disable-end unused-state
}

