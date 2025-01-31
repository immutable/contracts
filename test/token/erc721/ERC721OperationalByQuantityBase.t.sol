// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721OperationalBaseTest} from "./ERC721OperationalBase.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";


// Test the original ImmutableERC721 contract: Operational tests
abstract contract ERC721OperationalByQuantityBaseTest is ERC721OperationalBaseTest {
    IImmutableERC721ByQuantity public erc721BQ;

    function testThreshold() public {
        uint256 first = erc721BQ.mintBatchByQuantityThreshold();
        assertTrue(first >= 2**128);
    }

    function testMintByQuantity() public {
        mintSomeTokens();

        uint256 qty = 5;

        uint256 first = getFirst();
        uint256 originalBalance = erc721.balanceOf(user1);
        uint256 originalSupply = erc721.totalSupply();

        vm.prank(minter);
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(0), user1, first);
        emit Transfer(address(0), user1, first+1);
        emit Transfer(address(0), user1, first+2);
        emit Transfer(address(0), user1, first+3);
        emit Transfer(address(0), user1, first+4);
        erc721BQ.mintByQuantity(user1, qty);

        assertEq(erc721.balanceOf(user1), originalBalance + qty);
        assertEq(erc721.totalSupply(), originalSupply + qty);

        for (uint256 i = 0; i < qty; i++) {
            assertEq(erc721.ownerOf(first + i), user1);
        }
    }

    function testSafeMintByQuantity() public {
        mintSomeTokens();

        uint256 qty = 5;

        uint256 first = getFirst();
        uint256 originalBalance = erc721.balanceOf(user1);
        uint256 originalSupply = erc721.totalSupply();

        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user1, qty);

        assertEq(erc721.balanceOf(user1), originalBalance + qty);
        assertEq(erc721.totalSupply(), originalSupply + qty);

        for (uint256 i = 0; i < qty; i++) {
            assertEq(erc721.ownerOf(first + i), user1);
        }
    }

    function testBatchMintByQuantity() public {
        mintSomeTokens();

        uint256 qty = 5;
        IImmutableERC721.Mint[] memory mintRequests = new IImmutableERC721.Mint[](1);
        mintRequests[0].to = user1;
        mintRequests[0].quantity = qty;

        uint256 first = getFirst();
        uint256 originalBalance = erc721.balanceOf(user1);
        uint256 originalSupply = erc721.totalSupply();

        vm.prank(minter);
        erc721BQ.mintBatchByQuantity(mintRequests);

        assertEq(erc721.balanceOf(user1), originalBalance + qty);
        assertEq(erc721.totalSupply(), originalSupply + qty);

        for (uint256 i = 0; i < qty; i++) {
            assertEq(erc721.ownerOf(first + i), user1);
        }
    }

    function testSafeBatchMintByQuantity() public {
        mintSomeTokens();

        uint256 qty = 5;
        IImmutableERC721.Mint[] memory mintRequests = new IImmutableERC721.Mint[](1);
        mintRequests[0].to = user1;
        mintRequests[0].quantity = qty;

        uint256 first = getFirst();
        uint256 originalBalance = erc721.balanceOf(user1);
        uint256 originalSupply = erc721.totalSupply();

        vm.prank(minter);
        erc721BQ.safeMintBatchByQuantity(mintRequests);

        assertEq(erc721.balanceOf(user1), originalBalance + qty);
        assertEq(erc721.totalSupply(), originalSupply + qty);

        for (uint256 i = 0; i < qty; i++) {
            assertEq(erc721.ownerOf(first + i), user1);
        }
    }



    // function test_BurnBatch() public {
    //     uint256 originalBalance = erc721.balanceOf(user);
    //     uint256 originalSupply = erc721.totalSupply();
    //     uint256 first = erc721.mintBatchByQuantityThreshold();
        
    //     uint256[] memory batch = new uint256[](4);
    //     batch[0] = 3;
    //     batch[1] = 4;
    //     batch[2] = first;
    //     batch[3] = first + 1;

    //     vm.prank(user);
    //     erc721.burnBatch(batch);

    //     assertEq(erc721.balanceOf(user), originalBalance - batch.length);
    //     assertEq(erc721.totalSupply(), originalSupply - batch.length);
    // }

    // function test_RevertWhenNotApprovedToBurn() public {
    //     uint256 first = erc721.mintBatchByQuantityThreshold();
        
    //     uint256[] memory batch = new uint256[](2);
    //     batch[0] = first + 2;
    //     batch[1] = first + 3;

    //     vm.prank(minter);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IImmutableERC721.IImmutableERC721NotOwnerOrOperator.selector,
    //             first + 2
    //         )
    //     );
    //     erc721.burnBatch(batch);
    // }

    // function test_RevertWhenMintingAboveThreshold() public {
    //     uint256 first = erc721.mintBatchByQuantityThreshold();
        
    //     ImmutableERC721.MintRequest[] memory mintRequests = new ImmutableERC721.MintRequest[](1);
    //     uint256[] memory tokenIds = new uint256[](1);
    //     tokenIds[0] = first;
    //     mintRequests[0] = ImmutableERC721.MintRequest({
    //         to: user,
    //         tokenIds: tokenIds
    //     });

    //     vm.prank(minter);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IImmutableERC721.IImmutableERC721IDAboveThreshold.selector,
    //             first
    //         )
    //     );
    //     erc721.mintBatch(mintRequests);
    // }

    function testExistsForQuantityMinted() public {
        testMintByQuantity();
        assertTrue(erc721BQ.exists(getFirst()));
    }

    function testExistsForIdMinted() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        assertTrue(erc721BQ.exists(1));
    }

    function testExistsForInvalidTokenByQ() public {
        testMintByQuantity();
        assertFalse(erc721BQ.exists(getFirst()+10));
    }


    function testExistsForInvalidTokenByID() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        assertFalse(erc721BQ.exists(2));
    }


    function getFirst() internal view virtual returns (uint256) {
        return erc721BQ.mintBatchByQuantityThreshold();
    }

}