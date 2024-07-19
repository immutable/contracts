// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract MockFunctions {
    function succeed() public pure {
        // do nothing
    }

    function revertWithNoReason() public pure {
        revert();
    }

    function nonPermitted() public pure {
        // do nothing
    }
}
