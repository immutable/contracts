// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";

contract MockOffchainSource is IOffchainRandomSource {
    uint256 public nextIndex = 1000;
    bool public isReady;

    function setIsReady(bool _ready) external {
        isReady = _ready;
    }

    function requestOffchainRandom() external override(IOffchainRandomSource) returns (uint256 _fulfilmentIndex) {
        return nextIndex++;
    }

    function getOffchainRandom(uint256 _fulfilmentIndex)
        external
        view
        override(IOffchainRandomSource)
        returns (bytes32 _randomValue)
    {
        if (!isReady) {
            revert WaitForRandom();
        }
        return keccak256(abi.encodePacked(_fulfilmentIndex));
    }

    function isOffchainRandomReady(uint256 /* _fulfilmentIndex */ ) external view returns (bool) {
        return isReady;
    }
}
