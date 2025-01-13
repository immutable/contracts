// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import {ImmutableERC721ByQuantityPerfTest} from "./ImmutableERC721ByQuantityPerf.t.sol";
import {ImmutableERC721} from "../../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";

/**
 * ImmutableERC721ByQuantityPerfTest, but prefilling the contract with data.
 */
contract ImmutableERC721ByQuantityPerfPrefillTest is ImmutableERC721ByQuantityPerfTest {
    function setUpStart() public override {
        super.setUpStart();
        prefillWithNfts();
    }
}
