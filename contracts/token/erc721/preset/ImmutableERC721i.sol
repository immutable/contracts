pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import { ERC721Hybrid } from "../abstract/ERC721Hybrid.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { MintingAccessControl } from "../abstract/MintingAccessControl.sol";
import { ImmutableERC721HybridBase } from "../abstract/ImmutableERC721HybridBase.sol";

contract ImmutableERC721i is ImmutableERC721HybridBase {

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

    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mintByID(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _safeMintByID(to, tokenId);
    }

    function mintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mintByQuantity(to, quantity);
    }
    
    function safeMintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _safeMintByQuantity(to, quantity);
    }

    function mintBatchByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByQuantity(mints);
    }

    function safeMintBatchByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByQuantity(mints);
    }

    function mintBatch(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByIDToMultiple(mints);
    }

    function safeMintBatch(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByIDToMultiple(mints);
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