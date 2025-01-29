// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721ConfigBaseTest} from "./ERC721ConfigBase.t.sol";
import {ImmutableERC721V2} from "../../../contracts/token/erc721/preset/ImmutableERC721V2.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

contract ERC721ConfigV2Test is ERC721ConfigBaseTest {

    function setUp() public virtual override {
        super.setUp();

        ImmutableERC721V2 immutableERC721 = new ImmutableERC721V2(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, 300
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721 = IImmutableERC721(address(immutableERC721));

        vm.prank(owner);
        erc721.grantMinterRole(minter);
   }

    function notOwnedRevertError(uint256 _tokenIdToBeBurned) public pure override returns (bytes memory) {
        return abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721NotOwnerOrOperator.selector, _tokenIdToBeBurned);
    }
}