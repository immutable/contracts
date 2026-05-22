// Copyright Immutable Pty Ltd 2018 - 2026
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

contract MockFunctions {
    error RevertWithData(uint256 value);

    function succeed() public pure {
        // This function is intentionally left empty to simulate a successful call
    }

    function revertWithNoReason() public pure {
        revert();
    }

    function notPermitted() public pure {
        // This function is intentionally left empty to simulate a non-permitted action
    }

    function succeedWithUint256(uint256 value) public pure returns (uint256) {
        return value;
    }

    function revertWithData(uint256 value) public pure {
        revert RevertWithData(value);
    }
}
