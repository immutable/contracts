// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ERC721OperationalBaseTest} from "./ERC721OperationalBase.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {
    IImmutableERC721, IImmutableERC721Errors
} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {MockEIP1271Wallet} from "../../../contracts/mocks/MockEIP1271Wallet.sol";

// Test the original ImmutableERC721 contract: Operational tests
abstract contract ERC721OperationalByQuantityBaseTest is ERC721OperationalBaseTest {
    IImmutableERC721ByQuantity public erc721BQ;

    function testThreshold() public {
        uint256 first = erc721BQ.mintBatchByQuantityThreshold();
        assertTrue(first >= 2 ** 128);
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
        emit Transfer(address(0), user1, first + 1);
        emit Transfer(address(0), user1, first + 2);
        emit Transfer(address(0), user1, first + 3);
        emit Transfer(address(0), user1, first + 4);
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

    function testMintByQuantityBurn() public {
        uint256 qty = 5;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        vm.prank(user1);
        erc721BQ.burn(first + 1);
        assertEq(erc721.balanceOf(user1), qty - 1);
        assertEq(erc721.totalSupply(), qty - 1);
    }

    function testMintByQuantityBurnAlreadyBurnt() public {
        uint256 qty = 5;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        vm.prank(user1);
        erc721BQ.burn(first + 1);
        assertEq(erc721.balanceOf(user1), qty - 1);
        assertEq(erc721.totalSupply(), qty - 1);

        // Burn a token that has already been burnt
        vm.prank(user1);
        vm.expectRevert("ERC721Psi: operator query for nonexistent token");
        erc721BQ.burn(first + 1);
    }

    function testMintByQuantityBurnNonExistentToken() public {
        uint256 first = getFirst();
        vm.prank(user1);
        vm.expectRevert("ERC721Psi: operator query for nonexistent token");
        erc721BQ.burn(first + 1);
    }

    function testMintByQuantityBurnBatch() public {
        mintSomeTokens();
        uint256 originalSupply = erc721.totalSupply();
        uint256 user1Bal = erc721.balanceOf(user1);

        uint256 qty = 4;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        assertEq(erc721.balanceOf(user1), qty + user1Bal);
        assertEq(erc721.totalSupply(), qty + originalSupply);

        uint256[] memory batch = new uint256[](4);
        batch[0] = 2;
        batch[1] = 3;
        batch[2] = first;
        batch[3] = first + 1;

        vm.prank(user1);
        erc721.burnBatch(batch);
        assertEq(erc721.balanceOf(user1), qty + user1Bal - batch.length, "Final balance");
        assertEq(erc721.totalSupply(), originalSupply + qty - batch.length, "Final supply");
    }

    function testMintByQuantityBurnBatchNotApproved() public {
        mintSomeTokens();
        uint256 originalSupply = erc721.totalSupply();
        uint256 user1Bal = erc721.balanceOf(user1);

        uint256 qty = 4;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        uint256[] memory batch = new uint256[](1);
        batch[0] = first + 1;

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721NotOwnerOrOperator.selector, first + 1)
        );
        erc721.burnBatch(batch);
        assertEq(erc721.balanceOf(user1), qty + user1Bal, "Final balance");
        assertEq(erc721.totalSupply(), originalSupply + qty, "Final supply");
    }

    function testSingleMintAboveMintByQuantityThreshold() public {
        uint256 tokenId = getFirst();
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721IDAboveThreshold.selector, tokenId)
        );
        erc721BQ.mint(user1, tokenId);
    }

    function testMintByQuantityBurnWhenApproved() public {
        uint256 qty = 5;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        uint256 tokenId = first + 1;
        vm.prank(user1);
        erc721BQ.approve(user2, tokenId);

        vm.prank(user2);
        erc721BQ.burn(tokenId);
        assertEq(erc721.balanceOf(user1), qty - 1);
    }

    function testMintByQuantityTransferFrom() public {
        hackAddUser1ToAllowlist();
        uint256 qty = 5;
        uint256 first = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        uint256 tokenId = first + 1;
        vm.prank(user1);
        erc721.transferFrom(user1, user3, tokenId);
        assertEq(erc721.ownerOf(tokenId), user3);
    }

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
        assertFalse(erc721BQ.exists(getFirst() + 10));
    }

    function testExistsForInvalidTokenByID() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        assertFalse(erc721BQ.exists(2));
    }

    function testPermitApproveSpenderMintedByQuantity() public {
        testMintByQuantity();
        uint256 tokenId = getFirst();
        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = erc721.nonces(tokenId);
        assertEq(nonce, 0);

        bytes memory signature = getSignature(user1Pkey, user2, tokenId, nonce, deadline);
        assertFalse(user2 == erc721.getApproved(tokenId));

        vm.prank(user2);
        erc721.permit(user2, tokenId, deadline, signature);
        assertEq(erc721.getApproved(tokenId), user2);
    }

    function testByQuantitySafeTransferFrom() public {
        hackAddUser1ToAllowlist();
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        vm.prank(user1);
        erc721.safeTransferFrom(user1, user2, tokenId);
        assertEq(erc721.ownerOf(tokenId), user2, "Incorrect owner");
    }

    function testByQuantitySafeTransferFromNotApproved() public {
        hackAddUser1ToAllowlist();
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);
        vm.prank(user2);
        vm.expectRevert("ERC721Psi: transfer caller is not owner nor approved");
        erc721.safeTransferFrom(user1, user2, tokenId);
    }

    function testByQuantityTransferToContractWallet() public {
        MockEIP1271Wallet eip1271Wallet = new MockEIP1271Wallet(user1);
        hackAddUser1ToAllowlist();
        addAccountToAllowlist(address(eip1271Wallet));
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        vm.prank(user1);
        erc721.safeTransferFrom(user1, address(eip1271Wallet), tokenId);
        assertEq(erc721.ownerOf(tokenId), address(eip1271Wallet), "Incorrect owner");
    }

    function testByQuantityTransferContractNotWallet() public {
        hackAddUser1ToAllowlist();
        addAccountToAllowlist(address(this));
        uint256 qty = 1;
        uint256 tokenId = getFirst();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, qty);

        vm.prank(user1);
        vm.expectRevert("ERC721Psi: transfer to non ERC721Receiver implementer");
        erc721.safeTransferFrom(user1, address(this), tokenId);
    }

    function getFirst() internal view virtual returns (uint256) {
        return erc721BQ.mintBatchByQuantityThreshold();
    }
}
