// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721PerfTest} from "./ERC721Perf.t.sol";
import {ImmutableERC721} from "../../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {ImmutableERC721MintByID} from "../../../contracts/token/erc721/preset/ImmutableERC721MintByID.sol";

/**
 * Contract for ERC 721 by ID perfromance tests, for ImmutableERC721.sol (that is, v1).
 */
contract ImmutableERC721ByIdPerfTest is ERC721PerfTest {
    function setUpStart() public virtual override {
        super.setUpStart();

        ImmutableERC721MintByID immutableERC721 = new ImmutableERC721MintByID(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, 300
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721 = IImmutableERC721(address(immutableERC721));

        vm.prank(owner);
        erc721.grantMinterRole(minter);

        // Mint the first NFT to prefillUser1
        firstNftId = 0;
        vm.prank(minter);
        erc721.mint(prefillUser1, firstNftId);
   }

    function notOwnedRevertError(uint256 /* _tokenIdToBeBurned */) public pure override returns (bytes memory) {
        return "ERC721: caller is not token owner or approved";
    }
}
