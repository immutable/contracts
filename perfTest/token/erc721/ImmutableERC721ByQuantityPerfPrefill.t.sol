// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721ByQuantityPerfTest} from "./ImmutableERC721ByQuantityPerf.t.sol";

/**
 * ImmutableERC721ByQuantityPerfTest, but prefilling the contract with data.
 */
contract ImmutableERC721ByQuantityPerfPrefillTest is ImmutableERC721ByQuantityPerfTest {
    function setUpStart() public override {
        super.setUpStart();
        prefillWithNfts();
    }
}
