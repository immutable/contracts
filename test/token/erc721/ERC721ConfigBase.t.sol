// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {ERC721BaseTest} from "./ERC721Base.t.sol";


abstract contract ERC721ConfigBaseTest is ERC721BaseTest {

    function testContractDeployment() public {
        bytes32 adminRole = erc721.DEFAULT_ADMIN_ROLE();
        assertTrue(erc721.hasRole(adminRole, owner));
        
        assertEq(erc721.name(), name);
        assertEq(erc721.symbol(), symbol);
        assertEq(erc721.contractURI(), contractURI);
        assertEq(erc721.baseURI(), baseURI);

        // TODO what else to check?
    }

    function testMintingAccessControl() public {
        address[] memory admins = erc721.getAdmins();
        assertEq(admins[0], owner);

        // Test granting and revoking minter role
        bytes32 minterRole = erc721.MINTER_ROLE();
        assertFalse(erc721.hasRole(minterRole, user1));

        vm.prank(owner);
        erc721.grantMinterRole(user1);
        assertTrue(erc721.hasRole(minterRole, user1));

        vm.prank(owner);
        erc721.revokeMinterRole(user1);
        assertFalse(erc721.hasRole(minterRole, user1));
    }

    function testAccessControlForMinting() public {
        vm.prank(minter);
        erc721.mint(user1, 1);

        vm.prank(minter);
        erc721.safeMint(user1, 2);

        vm.prank(user1);
        // Note the test below is fragile. 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is user1's account number.
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc721.mint(user1, 3);

        vm.prank(user1);
        // Note the test below is fragile. 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is user1's account number.
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc721.safeMint(user1, 3);
    }

    function testMintBatchAccessControl() public {
        // Test batch minting
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](1);
        uint256[] memory tokenIds1 = new uint256[](1);
        tokenIds1[0] = 3;
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        vm.prank(minter);
        erc721.mintBatch(mintRequests);

        // Test safe batch minting
        mintRequests = new IImmutableERC721.IDMint[](1);
        tokenIds1 = new uint256[](1);
        tokenIds1[0] = 4;
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        vm.prank(minter);
        erc721.safeMintBatch(mintRequests);

        // Test batch minting without permission
        vm.prank(user1);
        // Note the test below is fragile. 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is user1's account number.
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc721.mintBatch(mintRequests);

        // Test safe batch minting without permission
        vm.prank(user1);
        // Note the test below is fragile. 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is user1's account number.
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc721.mintBatch(mintRequests);


    }

    function testBurnTokenYouDontOwn() public {
        vm.prank(minter);
        erc721.mint(user1, 1);
        vm.prank(minter);
        erc721.mint(user1, 2);
      
        // Test burning token you don't own
        vm.prank(user2);
        vm.expectRevert(notOwnedRevertError(2));
        //vm.expectRevert("ERC721: caller is not token owner or approved");
        erc721.burn(2);
    }
}