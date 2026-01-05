// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {ERC721BaseTest} from "./ERC721Base.t.sol";


abstract contract ERC721ConfigBaseTest is ERC721BaseTest {

    function testContractDeployment() public {
        bytes32 adminRole = erc721.DEFAULT_ADMIN_ROLE();
        assertTrue(erc721.hasRole(adminRole, owner));
        
        assertEq(erc721.name(), name);
        assertEq(erc721.symbol(), symbol);
        assertEq(erc721.contractURI(), contractURI);
        assertEq(erc721.baseURI(), baseURI);
        assertEq(erc721.totalSupply(), 0);

        vm.expectRevert("ERC721: invalid token ID");
        erc721.ownerOf(1);
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

    function testTokenURIWithBaseURISet() public {
        uint256 tokenId = 15;
        vm.prank(minter);
        erc721.mint(user1, tokenId);
        
        assertEq(
            erc721.tokenURI(tokenId),
            string(abi.encodePacked(baseURI, vm.toString(tokenId)))
        );
    }

    function testTokenURIRevertBurnt() public {
        uint256 tokenId = 20;
        vm.prank(minter);
        erc721.mint(user1, tokenId);
        vm.prank(user1);
        erc721.burn(tokenId);
        
        vm.expectRevert("ERC721: invalid token ID");
        erc721.tokenURI(tokenId);
    }

    function testBaseURIAdminCanUpdate() public {
        string memory newBaseURI = "New Base URI";
        vm.prank(owner);
        erc721.setBaseURI(newBaseURI);
        assertEq(erc721.baseURI(), newBaseURI);
    }

    function testTokenURIRevertNonExistent() public {
        vm.expectRevert("ERC721: invalid token ID");
        erc721.tokenURI(1001);
    }

    function testBaseURIRevertNonAdminSet() public {
        vm.prank(user1);
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        erc721.setBaseURI("New Base URI");
    }

    function testContractURIAdminCanUpdate() public {
        string memory newContractURI = "New Contract URI";
        vm.prank(owner);
        erc721.setContractURI(newContractURI);
        assertEq(erc721.contractURI(), newContractURI);
    }

    function testContractURIRevertNonAdminSet() public {
        vm.prank(user1);
        vm.expectRevert("AccessControl: account 0x29e3b139f4393adda86303fcdaa35f60bb7092bf is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        erc721.setContractURI("New Contract URI");
    }

    function testSupportedInterfaces() public view {
        // ERC165
        assertTrue(erc721.supportsInterface(0x01ffc9a7));
        // ERC721
        assertTrue(erc721.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(erc721.supportsInterface(0x5b5e139f));
        // ERC 4494
        assertTrue(erc721.supportsInterface(0x5604e225));
    }

    function testRoyaltiesCorrectRoyalties() public {
        mintSomeTokens();
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(2, salePrice);
        assertEq(receiver, feeReceiver);
        assertEq(royaltyAmount, calcFee(salePrice));
    }

    function testRoyaltiesAdminCanSetDefaultRoyaltyReceiver() public {
        mintSomeTokens();
        uint256 salePrice = 1 ether;
        feeNumerator = 500;
        vm.prank(owner);
        erc721.setDefaultRoyaltyReceiver(user1, feeNumerator);
        (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(2, salePrice);
        assertEq(receiver, user1);
        assertEq(royaltyAmount, calcFee(salePrice));
    }

    function testRoyaltyMinterCanSetTokenRoyaltyReceiver() public {
        mintSomeTokens();
        uint256 salePrice = 1 ether;
        
        vm.prank(minter);
        erc721.setNFTRoyaltyReceiver(2, user2, feeNumerator);
        
        (address receiver1,) = erc721.royaltyInfo(1, salePrice);
        (address receiver2,) = erc721.royaltyInfo(2, salePrice);
        
        assertEq(receiver1, feeReceiver);
        assertEq(receiver2, user2);
    }

    function testMinterCanSetBatchTokenRoyaltyReceiver() public {
        mintSomeTokens();
        uint256 salePrice = 1 ether;
        
        // Check initial receivers
        (address receiver3,) = erc721.royaltyInfo(3, salePrice);
        (address receiver4,) = erc721.royaltyInfo(4, salePrice);
        (address receiver5,) = erc721.royaltyInfo(5, salePrice);
        
        assertEq(receiver3, feeReceiver);
        assertEq(receiver4, feeReceiver);
        assertEq(receiver5, feeReceiver);
        
        // Set batch receivers
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        tokenIds[2] = 5;
        
        vm.prank(minter);
        erc721.setNFTRoyaltyReceiverBatch(tokenIds, user2, feeNumerator);
        
        // Verify new receivers
        (receiver3,) = erc721.royaltyInfo(3, salePrice);
        (receiver4,) = erc721.royaltyInfo(4, salePrice);
        (receiver5,) = erc721.royaltyInfo(5, salePrice);
        
        assertEq(receiver3, user2);
        assertEq(receiver4, user2);
        assertEq(receiver5, user2);
    }

}