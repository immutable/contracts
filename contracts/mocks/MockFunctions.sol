// SPDX-License-Identifier: Unlicense
// This file is part of the test code for GuardedMulticaller
pragma solidity ^0.8.19;

contract MockFunctions {
    // solhint-disable-next-line no-empty-blocks
    function succeed() public pure {
        // This function is intentionally left empty to simulate a successful call
    }

    function revertWithNoReason() public pure {
        // solhint-disable-next-line custom-errors,reason-string
        revert();
    }

    // solhint-disable-next-line no-empty-blocks
    function nonPermitted() public pure {
        // This function is intentionally left empty to simulate a non-permitted action
    }
}
