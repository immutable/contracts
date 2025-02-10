// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ERC721ConfigBaseTest} from "./ERC721ConfigBase.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

abstract contract ERC721ConfigByQuantityBaseTest is ERC721ConfigBaseTest {
    IImmutableERC721ByQuantity public erc721BQ;

    function notOwnedRevertError(uint256 _tokenIdToBeBurned) public pure override returns (bytes memory) {
        return abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721NotOwnerOrOperator.selector, _tokenIdToBeBurned);
    }

    function testByQuantityContractDeployment() public {
        uint256 tokenId = getFirst();
        vm.expectRevert("ERC721Psi: owner query for nonexistent token");
        erc721.ownerOf(tokenId);
    }


    // Note that Open Zeppelin ERC721 contract handles the tokenURI request
    function testByQuantityTokenURIWithBaseURISet() public {
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        assertEq(
            erc721.tokenURI(tokenId),
            string(abi.encodePacked(baseURI, vm.toString(tokenId)))
        );
    }

    // Note that Open Zeppelin ERC721 contract handles the tokenURI request
    function testByQuantityTokenURIRevertBurnt() public {
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        vm.prank(user1);
        erc721.burn(tokenId);
        
        vm.expectRevert("ERC721: invalid token ID");
        erc721.tokenURI(tokenId);
    }

    function getFirst() internal view virtual returns (uint256) {
        return erc721BQ.mintBatchByQuantityThreshold();
    }

}