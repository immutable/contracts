pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import { ERC721Immutable } from "../extensions/ERC721Immutable.sol";
import { ERC721HybridMinting } from "../extensions/ERC721HybridMinting.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721AccessControl } from "../extensions/ERC721AccessControl.sol";
import { ERC721Royalty } from "../extensions/ERC721Royalty.sol";

contract ImmutableERC721 is ERC721Immutable {

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
    ERC721Royalty(royaltyAllowlist_, royaltyReceiver_, feeNumerator_)
    ERC721HybridMinting(name_, symbol_)
    ERC721AccessControl(owner_) 
    ERC721Immutable(baseURI_, contractURI_) {

    }

    function mintByID(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mintByID(to, tokenId);
    }

    function batchMintByID(address to, uint256[] memory tokenIds) external onlyRole(MINTER_ROLE) {
        _batchMintByID(to, tokenIds);
    }

    function mintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mintByQuantity(to, quantity);
    }

    function batchMintByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchMintByQuantity(mints);
    }

    function batchMintByIDToMultiple(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _batchMintByIDToMultiple(mints);
    }

    

}