// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.20;

/**
 * @title GemGame - A simple contract that emits an event for the purpose of indexing off-chain
 * @author Immutable
 * @dev The GemGame contract is not designed to be upgradeable or extended
 */
contract GemGame {
    /// @notice Indicates that an account has earned a gem
    event GemEarned(address indexed account, uint256 timestamp);

    /**
     * @notice Function that emits a `GemEarned` event
     */
    function earnGem() external {
        emit GemEarned(msg.sender, block.timestamp);
    }
}
