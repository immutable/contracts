// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import {ERC721ByQuantityPerfTest} from "./ERC721ByQuantityPerf.t.sol";
import {ImmutableERC721} from "../../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";

/**
 * Contract for ERC 721 by quantity perfromance tests, for ImmutableERC721.sol (that is, v1).
 */
contract ImmutableERC721ByQuantityPerfTest is ERC721ByQuantityPerfTest {
    function setUp() public override {
        super.setUp();

        ImmutableERC721 immutableERC721 = new ImmutableERC721(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, 300
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721BQ = IImmutableERC721ByQuantity(address(immutableERC721));
    }
}
