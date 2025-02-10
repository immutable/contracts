// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721V2ByQuantityPerfTest} from "./ImmutableERC721V2ByQuantityPerf.t.sol";

/**
 * ImmutableERC721ByQuantityPerfTest, but prefilling the contract with data.
 */
contract ImmutableERC721V2ByQuantityPerfPrefillTest is ImmutableERC721V2ByQuantityPerfTest {
    function setUpStart() public override {
        super.setUpStart();
        prefillWithNfts();
    }
}
