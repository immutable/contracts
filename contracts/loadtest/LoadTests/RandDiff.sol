// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RandDao {
    uint256 public randao;
    uint256 public diff;

    constructor() {
        randao = block.prevrandao;
        diff = block.difficulty;
    }
}