// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";

// Wallet designed to check for a native transfer during unstake that fails.
// Not really an attack as such.
contract StakeHolderAttackWallet2 {
    StakeHolderNative public stakeHolder;
    constructor(address _stakeHolder) {
        stakeHolder = StakeHolderNative(_stakeHolder);
    }
    receive() external payable {
        // Cause a revert that has zero call data length. 
        assembly {
            revert(0, 0)
        }

    }
    function stake(uint256 _amount) external {
        stakeHolder.stake{value: _amount}(_amount);
    }
    function unstake(uint256 _amount) external {
        stakeHolder.unstake(_amount);
    }
}

