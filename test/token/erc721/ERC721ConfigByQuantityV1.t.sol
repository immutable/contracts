// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721ConfigByQuantityBaseTest} from "./ERC721ConfigByQuantityBase.t.sol";
import {ImmutableERC721} from "../../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

contract ERC721ConfigByQuantityV1Test is ERC721ConfigByQuantityBaseTest {

    function setUp() public virtual override {
        super.setUp();

        ImmutableERC721 immutableERC721 = new ImmutableERC721(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, feeNumerator
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721 = IImmutableERC721(address(immutableERC721));
        erc721BQ = IImmutableERC721ByQuantity(address(immutableERC721));

        vm.prank(owner);
        erc721.grantMinterRole(minter);
   }

}