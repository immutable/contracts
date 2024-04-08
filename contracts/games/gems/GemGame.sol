// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
pragma solidity =0.8.20;

/**
 * @title GemGame - A simple contract that emits an event.
 */
contract GemGame {
    event GemEarned(address indexed account, uint256 timestamp);

    function earnGem() external {
        emit GemEarned(msg.sender, block.timestamp);
    }
}
