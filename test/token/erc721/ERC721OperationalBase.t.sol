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
        vm.prank(minter);
        erc721.mint(user1, 1);
        vm.prank(minter);
        erc721.mint(user1, 2);
        assertEq(erc721.balanceOf(user1), 2);
        assertEq(erc721.totalSupply(), 2);

        vm.prank(user1);
        erc721.burn(1);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.totalSupply(), 1);
    }

    function testBurnTokenNotOwned() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        vm.prank(minter);
        erc721.mint(user1, 2);

        vm.prank(user2);
        vm.expectRevert(notOwnedRevertError(2));
        erc721.burn(2);
    }

    function testBurnNonExistentToken() public {
        vm.prank(user1);
        vm.expectRevert("ERC721: invalid token ID");
        erc721.burn(999);
    }





//  function test_RevertBurnWithIncorrectOwner() public {
//         vm.prank(minter);
//         vm.expectRevert("ERC721: token already minted");
//         erc721.mint(user1, 5);


//         vm.startPrank(user1);
//         vm.expectRevert(
//             abi.encodeWithSignature(
//                 "IImmutableERC721MismatchedTokenOwner(uint256,address)",
//                 5,
//                 user1
//             )
//         );
//         erc721.safeBurn(owner, 5);
//         vm.stopPrank();
//     }

//     function test_SafeBurnWithCorrectOwner() public {
//         // First mint a token to user
//         IImmutableERC721.IDMint[] memory requests = new IImmutableERC721.IDMint[](1);
//         uint256[] memory tokenIds1 = new uint256[](1);
//         tokenIds1[0] = 5;
//         requests[0].to = user1;
//         requests[0].tokenIds = tokenIds1;
        
//         vm.prank(minter);
//         erc721.mintBatch(requests);

//         uint256 originalBalance = erc721.balanceOf(user1);
//         uint256 originalSupply = erc721.totalSupply();

//         vm.prank(user1);
//         erc721.safeBurn(user1, 5);

//         assertEq(erc721.balanceOf(user1), originalBalance - 1);
//         assertEq(erc721.totalSupply(), originalSupply - 1);
//     }

//     function test_RevertBatchBurnWithIncorrectOwners() public {
//         // Setup: First mint tokens
//         IImmutableERC721.IDMint[] memory requests = new IImmutableERC721.IDMint[](2);
//         uint256[] memory tokenIds1 = new uint256[](3);
//         tokenIds1[0] = 12;
//         tokenIds1[1] = 13;
//         tokenIds1[2] = 14;
//         requests[0].to = owner;
//         requests[0].tokenIds = tokenIds1;

//         uint256[] memory tokenIds2 = new uint256[](3);
//         tokenIds2[0] = 9;
//         tokenIds2[1] = 10;
//         tokenIds2[2] = 11;
//         requests[0].to = user1;
//         requests[0].tokenIds = tokenIds2;

//         vm.prank(minter);
//         erc721.mintBatch(requests);

//         IImmutableERC721.IDBurn[] memory burns = new IImmutableERC721.IDBurn[](2);
//         tokenIds1 = new uint256[](3);
//         tokenIds1[0] = 12;
//         tokenIds1[1] = 13;
//         tokenIds1[2] = 14;
//         burns[0].owner = owner;
//         burns[0].tokenIds = tokenIds1;

//         tokenIds2 = new uint256[](3);
//         tokenIds2[0] = 9;
//         tokenIds2[1] = 10;
//         tokenIds2[2] = 11;
//         burns[1].owner = owner;
//         burns[1].tokenIds = tokenIds1;

//         vm.prank(user1);
//         vm.expectRevert(
//             abi.encodeWithSignature(
//                 "IImmutableERC721MismatchedTokenOwner(uint256,address)",
//                 12,
//                 owner
//             )
//         );
//         erc721.safeBurnBatch(burns);
//     }

    // function test_PreventMintingBurnedTokens() public {
    //     // First mint and burn a token
    //     IImmutableERC721.IDMint[] memory requests = new IImmutableERC721.IDMint[](1);
    //     requests[0] = IImmutableERC721.IDMint({
    //         to: user1,
    //         tokenIds: new uint256[](2)
    //     });
    //     requests[0].tokenIds = [1, 2];

    //     vm.prank(minter);
    //     erc721.mintBatch(requests);

    //     vm.prank(user1);
    //     erc721.safeBurn(user1, 1);

    //     // Try to mint the burned token
    //     vm.prank(minter);
    //     vm.expectRevert(
    //         abi.encodeWithSignature(
    //             "IImmutableERC721TokenAlreadyBurned(uint256)",
    //             1
    //         )
    //     );
    //     erc721.mintBatch(requests);
    // }

    // function test_RevertMintAboveThreshold() public {
    //     uint256 first = erc721.mintBatchByQuantityThreshold();
        
    //     IImmutableERC721.IDMint[] memory requests = new IImmutableERC721.IDMint[](1);
    //     requests[0] = IImmutableERC721.IDMint({
    //         to: user1,
    //         tokenIds: new uint256[](1)
    //     });
    //     requests[0].tokenIds[0] = first;

    //     vm.prank(minter);
    //     vm.expectRevert(
    //         abi.encodeWithSignature(
    //             "IImmutableERC721IDAboveThreshold(uint256)",
    //             first
    //         )
    //     );
    //     erc721.mintBatch(requests);
    // }


    // Additional test functions would follow...
}