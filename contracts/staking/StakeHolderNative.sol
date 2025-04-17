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
     * @inheritdoc IStakeHolder
     */
    function getToken() external pure returns (address) {
        return address(0);
    }

    /**
     * @inheritdoc StakeHolderBase
     */
    function _sendValue(address _to, uint256 _amount) internal override {
        // slither-disable-next-line low-level-calls
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
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderNativeGap;
    // slither-disable-end unused-state
}
