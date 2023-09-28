pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ERC721Psi, ERC721PsiBurnable} from "../erc721psi/ERC721PsiBurnable.sol";
// Errors
import {IImmutableERC721Errors} from "../../../errors/Errors.sol";

/*
This contract allows for minting with one of two strategies:
- ERC721: minting with specified tokenIDs (inefficient)
- ERC721Psi: minting in batches with consecutive tokenIDs (efficient)

All other ERC721 functions are supported, with routing logic depending on the tokenId.
*/

abstract contract ERC721Hybrid is ERC721PsiBurnable, ERC721, IImmutableERC721Errors {
    using BitMaps for BitMaps.BitMap;

    // The total number of tokens minted by ID, used in totalSupply()
    uint256 private _idMintTotalSupply = 0;

    /// @dev A mapping of tokens ids before the threshold that have been burned to prevent re-minting
    BitMaps.BitMap private _burnedTokens;

    /** @dev A singular batch transfer request. The length of the tos and tokenIds must be matching
     *  batch transfers will transfer the specified ids to their matching address via index.
     **/
    struct TransferRequest {
        address from;
        address[] tos;
        uint256[] tokenIds;
    }

    /// @dev A singular safe burn request.
    struct IDBurn {
        address owner;
        uint256[] tokenIds;
    }

    /// @dev A singular Mint by quantity request
    struct Mint {
        address to;
        uint256 quantity;
    }

    /// @dev A singular Mint by id request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) ERC721Psi(name_, symbol_) {}

    /** @dev returns the threshold that divides tokens that are minted by id and
     *  minted by quantity
     **/
    function mintBatchByQuantityThreshold() public pure virtual returns (uint256) {
        return 2 ** 128;
    }

    /// @dev returns the startTokenID for the minting by quantity section of the contract
    function _startTokenId() internal pure virtual override(ERC721Psi) returns (uint256) {
        return mintBatchByQuantityThreshold();
    }

    /// @dev mints number of tokens specified to the address given via erc721psi
    function _mintByQuantity(address to, uint256 quantity) internal {
        ERC721Psi._mint(to, quantity);
    }

    /// @dev safe mints number of tokens specified to the address given via erc721psi
    function _safeMintByQuantity(address to, uint256 quantity) internal {
        ERC721Psi._safeMint(to, quantity);
    }

    /// @dev mints number of tokens specified to a multiple specified addresses via erc721psi
    function _mintBatchByQuantity(Mint[] memory mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            Mint memory m = mints[i];
            _mintByQuantity(m.to, m.quantity);
        }
    }

    /// @dev safe mints number of tokens specified to a multiple specified addresses via erc721psi
    function _safeMintBatchByQuantity(Mint[] memory mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            Mint memory m = mints[i];
            _safeMintByQuantity(m.to, m.quantity);
        }
    }

    /// @dev mints by id to a specified address via erc721
    function _mintByID(address to, uint256 tokenId) internal {
        if (tokenId >= mintBatchByQuantityThreshold()) {
            revert IImmutableERC721IDAboveThreshold(tokenId);
        }

        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        ERC721._mint(to, tokenId);
        _idMintTotalSupply++;
    }

    /// @dev safe mints by id to a specified address via erc721
    function _safeMintByID(address to, uint256 tokenId) internal {
        if (tokenId >= mintBatchByQuantityThreshold()) {
            revert IImmutableERC721IDAboveThreshold(tokenId);
        }

        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        ERC721._safeMint(to, tokenId);
        _idMintTotalSupply++;
    }

    /// @dev mints multiple tokens by id to a specified address via erc721
    function _mintBatchByID(address to, uint256[] memory tokenIds) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintByID(to, tokenIds[i]);
        }
    }

    /// @dev safe mints multiple tokens by id to a specified address via erc721
    function _safeMintBatchByID(address to, uint256[] memory tokenIds) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMintByID(to, tokenIds[i]);
        }
    }

    /// @dev mints multiple tokens by id to multiple specified addresses via erc721
    function _mintBatchByIDToMultiple(IDMint[] memory mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            IDMint memory m = mints[i];
            _mintBatchByID(m.to, m.tokenIds);
        }
    }

    /// @dev safe mints multiple tokens by id to multiple specified addresses via erc721
    function _safeMintBatchByIDToMultiple(IDMint[] memory mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            IDMint memory m = mints[i];
            _safeMintBatchByID(m.to, m.tokenIds);
        }
    }

    /// @dev checks to see if tokenID exists in the collection
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /// @dev allows caller to burn a token by id
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert IImmutableERC721NotOwnerOrOperator(tokenId);
        }
        _burn(tokenId);
    }

    /// @dev allows caller to burn multiple tokens by id
    function burnBatch(uint256[] calldata tokenIDs) external {
        for (uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    /// @dev Burn a token, checking the owner of the token against the parameter first.
    function safeBurn(address owner, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != owner) {
            revert IImmutableERC721MismatchedTokenOwner(tokenId, currentOwner);
        }

        burn(tokenId);
    }

    /// @dev Burn a batch of tokens, checking the owner of each token first.
    function _safeBurnBatch(IDBurn[] memory burns) internal {
        for (uint i = 0; i < burns.length; i++) {
            IDBurn memory b = burns[i];
            for (uint j = 0; j < b.tokenIds.length; j++) {
                safeBurn(b.owner, b.tokenIds[j]);
            }
        }
    }

    /** @dev All methods below are overwritten functions from ERC721/ERC721Psi with split routing
     *  if the token id in the param is below the threshold the erc721 method is invoked. Else
     *  the erc721psi method is invoked. They then behave like their specified ancestors methods.
     **/
    function _exists(uint256 tokenId) internal view virtual override(ERC721, ERC721PsiBurnable) returns (bool) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._ownerOf(tokenId) != address(0) && (!_burnedTokens.get(tokenId));
        }
        return ERC721PsiBurnable._exists(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            ERC721._transfer(from, to, tokenId);
        } else {
            ERC721Psi._transfer(from, to, tokenId);
        }
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.ownerOf(tokenId);
        }
        return ERC721Psi.ownerOf(tokenId);
    }

    /** @dev burn a token by id, if the token is below the threshold it is burned via erc721
     *  additional tracking is added for erc721 to prevent re-minting
     **/
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721PsiBurnable) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            ERC721._burn(tokenId);
            _burnedTokens.set(tokenId);
            _idMintTotalSupply--;
        } else {
            ERC721PsiBurnable._burn(tokenId);
        }
    }

    function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._approve(to, tokenId);
        }
        return ERC721Psi._approve(to, tokenId);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual override(ERC721, ERC721Psi) returns (bool) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._isApprovedOrOwner(spender, tokenId);
        }
        return ERC721Psi._isApprovedOrOwner(spender, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._safeTransfer(from, to, tokenId, _data);
        }
        return ERC721Psi._safeTransfer(from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.safeTransferFrom(from, to, tokenId, _data);
        }
        return ERC721Psi.safeTransferFrom(from, to, tokenId, _data);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override(ERC721, ERC721Psi) returns (bool) {
        return ERC721.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.getApproved(tokenId);
        }
        return ERC721Psi.getApproved(tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.approve(to, tokenId);
        }
        return ERC721Psi.approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.transferFrom(from, to, tokenId);
        }
        return ERC721Psi.transferFrom(from, to, tokenId);
    }

    /** @dev methods below are overwritten to always invoke the erc721 equivalent due to linearisation
    they do not get invoked explicitly by any external minting methods in this contract and are only overwritten to satisfy
    the compiler
    */

    /** @dev overriding erc721 and erc721psi _safemint, super calls the `_safeMint` method of
     *  the erc721 implementation due to inheritance linearisation
     **/
    function _safeMint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        super._safeMint(to, tokenId);
    }

    /** @dev overriding erc721 and erc721psi _safemint, super calls the `_safeMint` method of
     *  the erc721 implementation due to inheritance linearisation
     **/
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual override(ERC721, ERC721Psi) {
        super._safeMint(to, tokenId, _data);
    }

    /** @dev overriding erc721 and erc721psi _safemint, super calls the `_mint` method of
     *  the erc721 implementation due to inheritance linearisation
     **/
    function _mint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        super._mint(to, tokenId);
    }

    /** @dev Overwritten functions with combined implementations, supply for the collection is summed as they
     *  are tracked differently by each minting strategy
     **/

    function balanceOf(address owner) public view virtual override(ERC721, ERC721Psi) returns (uint) {
        return ERC721.balanceOf(owner) + ERC721Psi.balanceOf(owner);
    }

    function totalSupply() public view override(ERC721PsiBurnable) returns (uint256) {
        return ERC721PsiBurnable.totalSupply() + _idMintTotalSupply;
    }

    /** @dev Overwritten functions with direct routing. The metadata of the collect remains the same regardless
     *  of the minting strategy used for the tokenID
     **/

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

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, ERC721Psi) {
        return ERC721.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        safeTransferFrom(from, to, tokenId, "");
    }
}
