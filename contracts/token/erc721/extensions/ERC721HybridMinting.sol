pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Psi, ERC721PsiBurnable } from "../erc721psi/ERC721PsiBurnable.sol";

/*
This contract allows for minting with one of two strategies:
- ERC721: minting with specified tokenIDs (inefficient)
- ERC721Psi: minting in batches with consecutive tokenIDs (efficient)

All other ERC721 functions are supported, with routing logic depending on the tokenId. 
*/

abstract contract ERC721HybridMinting is ERC721PsiBurnable, ERC721 {

    // The total number of tokens minted by ID, used in totalSupply()
    uint256 private _idMintTotalSupply = 0;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) ERC721Psi(name_, symbol_) {}

    function _bulkMintThreshold() internal pure virtual returns (uint256) {
        return 2**64;
    }

    function _startTokenId() internal pure override(ERC721Psi) returns (uint256) {
        return _bulkMintThreshold();
    }

    // Optimised minting functions
    struct Mint {
        address to;
        uint256 quantity;
    }

    function _mintByQuantity(address to, uint256 quantity) internal  {
        ERC721Psi._mint(to, quantity);
    }

    function _batchMintByQuantity(Mint[] memory mints) internal  {
        for (uint i = 0; i < mints.length; i++) {
            Mint memory m = mints[i];
            _mintByQuantity(m.to, m.quantity);
        }
    }

    function _mintByID(address to, uint256 tokenId) internal {
        require(tokenId < _bulkMintThreshold(), "must mint below threshold"); 
        ERC721._mint(to, tokenId);
        _idMintTotalSupply++;
    }

    function _batchMintByID(address to, uint256[] memory tokenIds) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintByID(to, tokenIds[i]);
        }
    }

    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    function _batchMintByIDToMultiple(IDMint[] memory mints) internal  {
        for (uint i = 0; i < mints.length; i++) {
            IDMint memory m = mints[i];
            _batchMintByID(m.to, m.tokenIds);
        }
    }

    // Overwritten functions from ERC721/ERC721Psi with split routing

    function _exists(uint256 tokenId) internal view virtual override(ERC721, ERC721PsiBurnable) returns (bool) {
        if (tokenId < _bulkMintThreshold()) {
            return ERC721._exists(tokenId);
        }
        return ERC721PsiBurnable._exists(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < _bulkMintThreshold()) {
            ERC721._transfer(from, to, tokenId);
        } else {
            ERC721Psi._transfer(from, to, tokenId);
        }
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        if (tokenId < _bulkMintThreshold()) {
            return ERC721.ownerOf(tokenId);
        }
        return ERC721Psi.ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721PsiBurnable) {
        if (tokenId < _bulkMintThreshold()) {
            ERC721._burn(tokenId);
            _idMintTotalSupply--;
        } else {
            ERC721PsiBurnable._burn(tokenId);
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function burnBatch(uint256[] calldata tokenIDs) external {
        for (uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    // 
    function _safeMint(address to, uint256 quantity) internal virtual override(ERC721, ERC721Psi) {
        return super._safeMint(to, quantity);
    }

    function _safeMint(address to, uint256 quantity, bytes memory _data) internal virtual override(ERC721, ERC721Psi) {
        return super._safeMint(to, quantity, _data);
    }

    //This function is used by BOTH

    function _mint(address to, uint256 quantity) internal virtual override(ERC721, ERC721Psi) { 
        super._mint(to, quantity);
    }


    // Overwritten functions with combined implementations

    function balanceOf(address owner) public view virtual override(ERC721, ERC721Psi) returns (uint) {
        return ERC721.balanceOf(owner) + ERC721Psi.balanceOf(owner);
    }

    function totalSupply() public override(ERC721PsiBurnable) view returns (uint256) {
        return ERC721PsiBurnable.totalSupply() + _idMintTotalSupply;
    }

    // Overwritten functions with direct routing

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.tokenURI(tokenId);
    }

    function name() public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.name();
    }

    function symbol() public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.symbol();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Psi, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721._baseURI();
    }

    function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        return ERC721._approve(to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721, ERC721Psi) returns (bool) {
        return ERC721._isApprovedOrOwner(spender, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override(ERC721, ERC721Psi) { 
        return ERC721._safeTransfer(from, to, tokenId, _data);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, ERC721Psi) { 
        return ERC721.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721, ERC721Psi) {
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, ERC721Psi) returns (bool) {
        return ERC721.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        return ERC721.getApproved(tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) { 
        ERC721.approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        ERC721.transferFrom(from, to, tokenId);
    }

    // function safeTransferFromBatch(TransferRequest calldata tr) external {
    //     if (tr.tokenIds.length != tr.tos.length) {
    //         revert("number of token ids not the same as number of receivers");
    //     }

    //     for (uint i = 0; i < tr.tokenIds.length; i++) {
    //         safeTransferFrom(tr.from, tr.tos[i], tr.tokenIds[i]);
    //     }
    // }

}