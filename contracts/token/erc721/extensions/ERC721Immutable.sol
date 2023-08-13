pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import { ERC721Royalty } from "../extensions/ERC721Royalty.sol";
import { ERC721HybridMinting } from "../extensions/ERC721HybridMinting.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721AccessControl } from "../extensions/ERC721AccessControl.sol";

abstract contract ERC721Immutable is ERC721HybridMinting, ERC721Royalty {

        /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string public baseURI;

    constructor(
        string memory baseURI_,
        string memory contractURI_
    ) {
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    /// @dev Allows admin to set the base URI
    function setBaseURI(
        string memory baseURI_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(
        string memory _contractURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    // Overwritten

    function _exists(uint256 tokenId) internal view override(ERC721, ERC721HybridMinting) returns (bool) {
        return ERC721HybridMinting._exists(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721Royalty, ERC721HybridMinting) {
        ERC721HybridMinting._transfer(from, to, tokenId);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, ERC721HybridMinting) returns (address) {
        return ERC721HybridMinting.ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721HybridMinting) {
        return ERC721HybridMinting._burn(tokenId);
    }

    function balanceOf(address owner) public view virtual override(ERC721, ERC721HybridMinting) returns (uint) {
        return ERC721HybridMinting.balanceOf(owner);
    }

    // 
    function _safeMint(address to, uint256 quantity) internal virtual override(ERC721, ERC721HybridMinting) {
        return _safeMint(to, quantity, "");
    }

    function _safeMint(address to, uint256 quantity, bytes memory _data) internal virtual override(ERC721, ERC721HybridMinting) {
        return ERC721HybridMinting._safeMint(to, quantity, _data);
    }


    function _mint(address to, uint256 quantity) internal virtual override(ERC721, ERC721HybridMinting) { 
        ERC721HybridMinting._mint(to, quantity);
    }

    // Overwritten functions with direct routing

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721HybridMinting) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function name() public view virtual override(ERC721, ERC721HybridMinting) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC721, ERC721HybridMinting) returns (string memory) {
        return super.symbol();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721HybridMinting, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721HybridMinting, ERC721) returns (string memory) {
        return baseURI;
    }

    function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721HybridMinting) {
        return super._approve(to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721, ERC721HybridMinting) returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override(ERC721, ERC721HybridMinting) { 
        return super._safeTransfer(from, to, tokenId, _data);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721Royalty, ERC721HybridMinting) { 
        return super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721HybridMinting) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721, ERC721HybridMinting) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, ERC721HybridMinting) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public view virtual override(ERC721, ERC721HybridMinting) returns (address) {
        return super.getApproved(tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721Royalty, ERC721HybridMinting) { 
        super.approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721HybridMinting) {
        super.transferFrom(from, to, tokenId);
    }


}