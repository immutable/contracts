// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ERC721ConfigBaseTest} from "./ERC721ConfigBase.t.sol";
import {ImmutableERC721MintByID} from "../../../contracts/token/erc721/preset/ImmutableERC721MintByID.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

contract ERC721ConfigV1ByIdTest is ERC721ConfigBaseTest {

    function setUp() public virtual override {
        super.setUp();

        ImmutableERC721MintByID immutableERC721 = new ImmutableERC721MintByID(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, feeNumerator
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721 = IImmutableERC721(address(immutableERC721));

        vm.prank(owner);
        erc721.grantMinterRole(minter);
   }

    function notOwnedRevertError(uint256 /* _tokenIdToBeBurned */) public pure override returns (bytes memory) {
        return "ERC721: caller is not token owner or approved";
    }
}