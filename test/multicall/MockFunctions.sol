// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

contract MockFunctions {
    error RevertWithData(uint256 value);

    // solhint-disable-next-line no-empty-blocks
    function succeed() public pure {
        // This function is intentionally left empty to simulate a successful call
    }

    function revertWithNoReason() public pure {
        // solhint-disable-next-line custom-errors,reason-string
        revert();
    }

    // solhint-disable-next-line no-empty-blocks
    function notPermitted() public pure {
        // This function is intentionally left empty to simulate a non-permitted action
    }

    function succeedWithUint256(uint256 value) public pure returns (uint256) {
        return value;
    }

    function revertWithData(uint256 value) public pure {
        // solhint-disable-next-line custom-errors,reason-string
        revert RevertWithData(value);
    }
} 