// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {Test} from "forge-std/Test.sol";
import {ImmutableERC721MintByID} from "../../contracts/token/erc721/preset/ImmutableERC721MintByID.sol";
import {MockMarketplace} from "./MockMarketplace.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {DeployOperatorAllowlist} from "../utils/DeployAllowlistProxy.sol";


contract RoyaltyMarketplaceTest is Test {
    ImmutableERC721MintByID public erc721;
    OperatorAllowlistUpgradeable public operatorAllowlist;
    MockMarketplace public mockMarketplace;
    
    address public owner;
    address public minter;
    address public registrar;
    address public royaltyRecipient;
    address public buyer;
    address public seller;
    
    string public constant BASE_URI = "https://baseURI.com/";
    string public constant contractURI = "https://contractURI.com";
    string public constant name = "ERC721Preset";
    string public constant symbol = "EP";
    uint96 public constant ROYALTY = 2000; // 20%
    
    function setUp() public {
        // Set up accounts
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        registrar = makeAddr("registrar");
        royaltyRecipient = makeAddr("royaltyRecipient");
        buyer = makeAddr("buyer");
        seller = makeAddr("seller");
        
        // Deploy operator Allowlist
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        address proxyAddr = deployScript.run(owner, owner, registrar);
        operatorAllowlist = OperatorAllowlistUpgradeable(proxyAddr);
        
        // Deploy ERC721 contract
        vm.prank(owner);
        erc721 = new ImmutableERC721MintByID(
            owner,
            name,
            symbol,
            BASE_URI,
            contractURI,
            address(operatorAllowlist),
            royaltyRecipient,
            ROYALTY
        );

        // Deploy mock marketplace
        mockMarketplace = new MockMarketplace(address(erc721));

        // Set up roles
        vm.prank(owner);
        erc721.grantMinterRole(minter);
    }
    
    function test_AllowlistMarketplace() public {
        address[] memory marketPlaces = new address[](1);
        marketPlaces[0] = address(mockMarketplace);

        vm.prank(registrar);
        operatorAllowlist.addAddressesToAllowlist(marketPlaces);

        assertTrue(operatorAllowlist.isAllowlisted(address(mockMarketplace)));
    }

    function test_EnforceRoyalties() public {
        // Add the market place to the operator allow list.
        test_AllowlistMarketplace();

        uint256 tokenId = 1;

        // Get royalty info
        uint256 salePrice = 1 ether;
        (, uint256 royaltyAmount) = erc721.royaltyInfo(tokenId, salePrice);

        // Mint NFT to seller
        vm.prank(minter);
        erc721.mint(seller, tokenId);

        // Approve marketplace
        vm.prank(seller);
        erc721.setApprovalForAll(address(mockMarketplace), true);

        // Get pre-trade balances
        uint256 recipientBal = royaltyRecipient.balance;
        uint256 sellerBal = seller.balance;

        // Execute trade
        vm.deal(buyer, salePrice);
        vm.prank(buyer);
        mockMarketplace.executeTransferRoyalties{value: salePrice}(
            seller,
            buyer,
            tokenId,
            salePrice
        );

        // Check if buyer received NFT
        assertEq(erc721.ownerOf(tokenId), buyer, "Buyer does not have NFT");

        // Check if royalty recipient has increased balance
        assertEq(royaltyRecipient.balance, recipientBal + royaltyAmount, "Royalty receiver balance not correct");

        // Check if seller has increased balance
        assertEq(seller.balance, sellerBal + (salePrice - royaltyAmount), "Seller balance not correct");
    }
} 