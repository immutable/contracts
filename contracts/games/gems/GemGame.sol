// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
// solhint-disable not-rely-on-time
pragma solidity ^0.8.19;

error TooSoon();

/**
 * @title GemGame - A simple contract that emits an event for the purpose of indexing off-chain
 * @author Immutable
 * @dev The GemGame contract is not designed to be upgradeable or extended
 */
contract GemGame {
    /// @notice Indicates that an account has earned a gem
    event GemEarned(address indexed account, uint256 timestamp);

    /// @notice Mapping of the last time an account earned a gem
    mapping(address account => uint256 lastEarned) public accountLastEarned;

    /**
     * @notice Function that emits a `GemEarned` event
     */
    function earnGem() external {
        // Get the timestamp of midnight UTC for the current block
        uint256 utcMidnight = block.timestamp - block.timestamp % (24 * 60 * 60);

        // Check if the account has already earned a gem today
        // If their last earned timestamp is less than midnight UTC, they can earn a gem
        if (accountLastEarned[msg.sender] < utcMidnight) revert TooSoon();

        // Set the last earned timestamp to the current block timestamp
        accountLastEarned[msg.sender] = block.timestamp;

        // User has earned a gem
        emit GemEarned(msg.sender, block.timestamp);
    }
}
