// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";

// Wallet designed to attempt reentrancy attacks
contract StakeHolderAttackWallet {
    StakeHolderNative public stakeHolder;
    constructor(address _stakeHolder) {
        stakeHolder = StakeHolderNative(_stakeHolder);
    }
    receive() external payable {
        // Assumung the call to unstake is for a "whole" number, say 1 ether, then
        // this if statement will be chosen first time through the loop. The second 
        // time through, the msg.value will have the bottom bit set, and this if 
        // statement will be skipped.
        if (msg.value & 0x01 == 0) {
            stakeHolder.unstake(msg.value + 1);
        }
    }
    function stake(uint256 _amount) external {
        stakeHolder.stake{value: _amount}(_amount);
    }
    function unstake(uint256 _amount) external {
        stakeHolder.unstake(_amount);
    }
}

