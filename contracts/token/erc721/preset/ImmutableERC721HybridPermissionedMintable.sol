pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import { ERC721Hybrid } from "../abstract/ERC721Hybrid.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { MintingAccessControl } from "../abstract/MintingAccessControl.sol";
import { ImmutableERC721HybridBase } from "../abstract/ImmutableERC721HybridBase.sol";

contract ImmutableERC721HybridPermissionedMintable is ImmutableERC721HybridBase {

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address royaltyAllowlist_,
        address royaltyReceiver_,
        uint96 feeNumerator_
    ) 
    ImmutableERC721HybridBase(owner_, name_, symbol_, baseURI_, contractURI_, royaltyAllowlist_, royaltyReceiver_, feeNumerator_)
    {}

    function mintByID(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mintByID(to, tokenId);
    }

    function safeMintByID(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _safeMintByID(to, tokenId);
    }

    function mintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mintByQuantity(to, quantity);
    }
    
    function safeMintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _safeMintByQuantity(to, quantity);
    }

    function batchMintByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchMintByQuantity(mints);
    }

    function batchSafeMintByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchSafeMintByQuantity(mints);
    }

    function batchMintByIDToMultiple(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchMintByIDToMultiple(mints);
    }

    function batchSafeMintByIDToMultiple(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchSafeMintByIDToMultiple(mints);
    }

    function safeTransferFromBatch(TransferRequest calldata tr) external {
        if (tr.tokenIds.length != tr.tos.length) {
            revert IImmutableERC721MismatchedTransferLengths();
        }

        for (uint i = 0; i < tr.tokenIds.length; i++) {
            safeTransferFrom(tr.from, tr.tos[i], tr.tokenIds[i]);
        }
    }

}