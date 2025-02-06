// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721BaseTest} from "./ERC721Base.t.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

abstract contract ERC721OperationalBaseTest is ERC721BaseTest {


    function testMint() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.totalSupply(), 1);
        assertEq(erc721.ownerOf(1), user1);
    }

    function testSafeMint() public {
        vm.prank(minter);
        erc721.safeMint(user1, 2);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.totalSupply(), 1);
        assertEq(erc721.ownerOf(2), user1);
    }

    function testMintBatch() public {
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](2);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 4;
        tokenIds1[2] = 5;
        uint256[] memory tokenIds2 = new uint256[](2);
        tokenIds2[0] = 6;
        tokenIds2[1] = 7;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        mintRequests[1].to = user2;
        mintRequests[1].tokenIds = tokenIds2;

        vm.prank(minter);
        erc721.mintBatch(mintRequests);
        
        assertEq(erc721.balanceOf(user1), 3);
        assertEq(erc721.balanceOf(user2), 2);
        assertEq(erc721.totalSupply(), 5);
        assertEq(erc721.ownerOf(3), user1);
        assertEq(erc721.ownerOf(4), user1);
        assertEq(erc721.ownerOf(5), user1);
        assertEq(erc721.ownerOf(6), user2);
        assertEq(erc721.ownerOf(7), user2);
    }

    function testSafeMintBatch() public {
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](2);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 4;
        tokenIds1[2] = 5;
        uint256[] memory tokenIds2 = new uint256[](2);
        tokenIds2[0] = 6;
        tokenIds2[1] = 7;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        mintRequests[1].to = user2;
        mintRequests[1].tokenIds = tokenIds2;

        vm.prank(minter);
        erc721.safeMintBatch(mintRequests);
        
        assertEq(erc721.balanceOf(user1), 3);
        assertEq(erc721.balanceOf(user2), 2);
        assertEq(erc721.totalSupply(), 5);
        assertEq(erc721.ownerOf(3), user1);
        assertEq(erc721.ownerOf(4), user1);
        assertEq(erc721.ownerOf(5), user1);
        assertEq(erc721.ownerOf(6), user2);
        assertEq(erc721.ownerOf(7), user2);
    }

    function testDuplicateMint() public {
        testMint();
        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.mint(user1, 1);
    }

    function testDuplicateSafeMint() public {
        testMint();
        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.safeMint(user1, 1);
    }

    function testDuplicateMintBatch() public {
        testMint();
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](1);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 1;
        tokenIds1[2] = 5;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;

        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.mintBatch(mintRequests);
    }

    function testDuplicateSafeMintBatch() public {
        testMint();
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](1);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 1;
        tokenIds1[2] = 5;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;

        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.safeMintBatch(mintRequests);
    }

    function testDuplicateMintBatchWithBatch() public {
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](1);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 1;
        tokenIds1[2] = 3;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;

        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.mintBatch(mintRequests);
    }

    function testDuplicateSafeMintBatchWithinBatch() public {
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](1);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 1;
        tokenIds1[2] = 3;
        
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;

        vm.prank(minter);
        vm.expectRevert("ERC721: token already minted");
        erc721.safeMintBatch(mintRequests);
    }

    function testBurn() public {
        mintSomeTokens();

        vm.prank(user1);
        erc721.burn(1);
        assertEq(erc721.balanceOf(user1), 2);
        assertEq(erc721.totalSupply(), 4);
    }

    function testSafeBurn() public {
        mintSomeTokens();

        vm.prank(user1);
        erc721.safeBurn(user1, 1);
        assertEq(erc721.balanceOf(user1), 2);
        assertEq(erc721.totalSupply(), 4);
    }

    function testSafeBurnTokenNotOwned() public {
        mintSomeTokens();

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721MismatchedTokenOwner.selector, 2, user1));
        erc721.safeBurn(user2, 2);
    }

    function testSafeBurnIncorrectOwner() public {
        mintSomeTokens();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721MismatchedTokenOwner.selector, 2, user1));
        erc721.safeBurn(user2, 2);
    }

    function testSafeBurnNonExistentToken() public {
        mintSomeTokens();

        vm.prank(user1);
        vm.expectRevert("ERC721: invalid token ID");
        erc721.safeBurn(user1, 999);
    }

    function testBurnBatch() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 3;

        vm.prank(user1);
        erc721.burnBatch(tokenIds1);
    }

    function testBurnBatchIncorrectOwner() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 3;

        vm.prank(user2);
        vm.expectRevert(notOwnedRevertError(2));
        erc721.burnBatch(tokenIds1);
    }

    function testBurnBatchNonExistentToken() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 11;

        vm.prank(user1);
        vm.expectRevert("ERC721: invalid token ID");
        erc721.burnBatch(tokenIds1);
    }

    function testSafeBurnBatch() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 3;
        IImmutableERC721.IDBurn[] memory burnRequests = new IImmutableERC721.IDBurn[](1);
        burnRequests[0].owner = user1;
        burnRequests[0].tokenIds = tokenIds1;

        vm.prank(user1);
        erc721.safeBurnBatch(burnRequests);
    }

    function testSafeBurnBatchIncorrectOwner() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 3;
        IImmutableERC721.IDBurn[] memory burnRequests = new IImmutableERC721.IDBurn[](1);
        burnRequests[0].owner = user1;
        burnRequests[0].tokenIds = tokenIds1;

        vm.prank(user2);
        vm.expectRevert(notOwnedRevertError(2));
        erc721.safeBurnBatch(burnRequests);
    }

    function testSafeBurnBatchNonExistentToken() public {
        mintSomeTokens();

        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 2;
        tokenIds1[1] = 11;
        IImmutableERC721.IDBurn[] memory burnRequests = new IImmutableERC721.IDBurn[](1);
        burnRequests[0].owner = user1;
        burnRequests[0].tokenIds = tokenIds1;

        vm.prank(user1);
        vm.expectRevert("ERC721: invalid token ID");
        erc721.safeBurnBatch(burnRequests);
    }

    function testPreventMintingBurnedTokens() public {
        mintSomeTokens();

        vm.prank(user1);
        erc721.safeBurn(user1, 1);

        // Try to mint the burned token
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721TokenAlreadyBurned.selector, 1)
        );
        erc721.mint(user3, 1);
    }

    function testBurnWhenApproved() public {
        uint256 tokenId = 5;
        vm.prank(minter);
        erc721.mint(user1, tokenId);
        vm.prank(user1);
        erc721.approve(user2, tokenId);

        vm.prank(user2);
        erc721.burn(tokenId);
        assertEq(erc721.balanceOf(user1), 0);
    }




// Royalties
// Transfers




}