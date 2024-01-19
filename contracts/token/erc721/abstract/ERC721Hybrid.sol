// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

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

    /// @notice The total number of tokens minted by ID, used in totalSupply()
    uint256 private _idMintTotalSupply = 0;

    /// @notice A mapping of tokens ids before the threshold that have been burned to prevent re-minting
    BitMaps.BitMap private _burnedTokens;

    /** @notice A singular batch transfer request. The length of the tos and tokenIds must be matching
     *  batch transfers will transfer the specified ids to their matching address via index.
     **/
    struct TransferRequest {
        address from;
        address[] tos;
        uint256[] tokenIds;
    }

    /// @notice A singular safe burn request.
    struct IDBurn {
        address owner;
        uint256[] tokenIds;
    }

    /// @notice A singular Mint by quantity request
    struct Mint {
        address to;
        uint256 quantity;
    }

    /// @notice A singular Mint by id request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) ERC721Psi(name_, symbol_) {}

    /** @notice allows caller to burn multiple tokens by id
     *  @param tokenIDs an array of token ids
     */ 
    function burnBatch(uint256[] calldata tokenIDs) external {
        for (uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    /** @notice burns the specified token id
     *  @param tokenId the id of the token to burn
     */ 
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert IImmutableERC721NotOwnerOrOperator(tokenId);
        }
        _burn(tokenId);
    }

    /** @notice Burn a token, checking the owner of the token against the parameter first.
     *  @param owner the owner of the token
     *  @param tokenId the id of the token to burn
     */ 
    function safeBurn(address owner, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != owner) {
            revert IImmutableERC721MismatchedTokenOwner(tokenId, currentOwner);
        }

        burn(tokenId);
    }

    /** @notice returns the threshold that divides tokens that are minted by id and
     *  minted by quantity
     */
    function mintBatchByQuantityThreshold() public pure virtual returns (uint256) {
        return 2 ** 128;
    }
    
    /** @notice checks to see if tokenID exists in the collection
     *  @param tokenId the id of the token to check
     **/
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /** @notice Overwritten functions with combined implementations, supply for the collection is summed as they
     *  are tracked differently by each minting strategy
     */
    function balanceOf(address owner) public view virtual override(ERC721, ERC721Psi) returns (uint) {
        return ERC721.balanceOf(owner) + ERC721Psi.balanceOf(owner);
    }

    /* @notice Overwritten functions with combined implementations, supply for the collection is summed as they
     *  are tracked differently by each minting strategy
     */
    function totalSupply() public view override(ERC721PsiBurnable) returns (uint256) {
        return ERC721PsiBurnable.totalSupply() + _idMintTotalSupply;
    }
    
    /** @notice refer to erc721 or erc721psi */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.ownerOf(tokenId);
        }
        return ERC721Psi.ownerOf(tokenId);
    }

    /** @notice Overwritten functions with direct routing. The metadata of the collect remains the same regardless
     *  of the minting strategy used for the tokenID
     */

    /**
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.tokenURI(tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function name() public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.name();
    }

    /**
     * @inheritdoc ERC721
     */
    function symbol() public view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721.symbol();
    }

    /**
     * @inheritdoc ERC721
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Psi, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, ERC721Psi) {
        return ERC721.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** @notice refer to erc721 or erc721psi */
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

    /** @notice refer to erc721 or erc721psi */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override(ERC721, ERC721Psi) returns (bool) {
        return ERC721.isApprovedForAll(owner, operator);
    }

    /** @notice refer to erc721 or erc721psi */
    function getApproved(uint256 tokenId) public view virtual override(ERC721, ERC721Psi) returns (address) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.getApproved(tokenId);
        }
        return ERC721Psi.getApproved(tokenId);
    }

    /** @notice refer to erc721 or erc721psi */
    function approve(address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.approve(to, tokenId);
        }
        return ERC721Psi.approve(to, tokenId);
    }

    /** @notice refer to erc721 or erc721psi */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721.transferFrom(from, to, tokenId);
        }
        return ERC721Psi.transferFrom(from, to, tokenId);
    }

    /** @notice mints number of tokens specified to the address given via erc721psi
     *  @param to the address to mint to
     *  @param quantity the number of tokens to mint
     */ 
    function _mintByQuantity(address to, uint256 quantity) internal {
        ERC721Psi._mint(to, quantity);
    }

    /** @notice safe mints number of tokens specified to the address given via erc721psi
     *  @param to the address to mint to
     *  @param quantity the number of tokens to mint
     */ 
    function _safeMintByQuantity(address to, uint256 quantity) internal {
        ERC721Psi._safeMint(to, quantity);
    }

    /** @notice mints number of tokens specified to a multiple specified addresses via erc721psi
     *  @param mints an array of mint requests
     */ 
    function _mintBatchByQuantity(Mint[] calldata mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            Mint calldata m = mints[i];
            _mintByQuantity(m.to, m.quantity);
        }
    }

    /** @notice safe mints number of tokens specified to a multiple specified addresses via erc721psi
     *  @param mints an array of mint requests
     */ 
    function _safeMintBatchByQuantity(Mint[] calldata mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            Mint calldata m = mints[i];
            _safeMintByQuantity(m.to, m.quantity);
        }
    }

    
    /** @notice safe mints number of tokens specified to a multiple specified addresses via erc721
     *  @param to the address to mint to
     *  @param tokenId the id of the token to mint
     */ 
    function _mintByID(address to, uint256 tokenId) internal {
        if (tokenId >= mintBatchByQuantityThreshold()) {
            revert IImmutableERC721IDAboveThreshold(tokenId);
        }

        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        
        _idMintTotalSupply++;
        ERC721._mint(to, tokenId);
    }

    /** @notice safe mints number of tokens specified to a multiple specified addresses via erc721
     *  @param to the address to mint to
     *  @param tokenId the id of the token to mint
     */
    function _safeMintByID(address to, uint256 tokenId) internal {
        if (tokenId >= mintBatchByQuantityThreshold()) {
            revert IImmutableERC721IDAboveThreshold(tokenId);
        }

        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }

        _idMintTotalSupply++;
        ERC721._safeMint(to, tokenId);    
    }

    /** @notice mints multiple tokens by id to a specified address via erc721 
     *  @param to the address to mint to
     *  @param tokenIds the ids of the tokens to mint
     */
    function _mintBatchByID(address to, uint256[] calldata tokenIds) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintByID(to, tokenIds[i]);
        }
    }

    /** @notice safe mints multiple tokens by id to a specified address via erc721 
     *  @param to the address to mint to
     *  @param tokenIds the ids of the tokens to mint
     **/
    function _safeMintBatchByID(address to, uint256[] calldata tokenIds) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMintByID(to, tokenIds[i]);
        }
    }

    /** @notice mints multiple tokens by id to multiple specified addresses via erc721
     *  @param mints an array of mint requests
     */
    function _mintBatchByIDToMultiple(IDMint[] calldata mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            IDMint calldata m = mints[i];
            _mintBatchByID(m.to, m.tokenIds);
        }
    }

    /** @notice safe mints multiple tokens by id to multiple specified addresses via erc721
     *  @param mints an array of mint requests
     */
    function _safeMintBatchByIDToMultiple(IDMint[] calldata mints) internal {
        for (uint i = 0; i < mints.length; i++) {
            IDMint calldata m = mints[i];
            _safeMintBatchByID(m.to, m.tokenIds);
        }
    }

    /** @notice batch burn a tokens by id, checking the owner of the token against the parameter first.
     *  @param burns array of burn requests 
     */ 
    function _safeBurnBatch(IDBurn[] calldata burns) internal {
        for (uint i = 0; i < burns.length; i++) {
            IDBurn calldata b = burns[i];
            for (uint j = 0; j < b.tokenIds.length; j++) {
                safeBurn(b.owner, b.tokenIds[j]);
            }
        }
    }

    /** @notice refer to erc721 or erc721psi */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            ERC721._transfer(from, to, tokenId);
        } else {
            ERC721Psi._transfer(from, to, tokenId);
        }
    }

    /** @notice burn a token by id, if the token is below the threshold it is burned via erc721
     *  additional tracking is added for erc721 to prevent re-minting. Refer to erc721 or erc721psi
     *  @param tokenId the id of the token to burn
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721PsiBurnable) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            ERC721._burn(tokenId);
            _burnedTokens.set(tokenId);
            _idMintTotalSupply--;
        } else {
            ERC721PsiBurnable._burn(tokenId);
        }
    }

    /** @notice refer to erc721 or erc721psi */
    function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._approve(to, tokenId);
        }
        return ERC721Psi._approve(to, tokenId);
    }

    /** @notice refer to erc721 or erc721psi */
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

    /** @notice methods below are overwritten to always invoke the erc721 equivalent due to linearisation
     *  they do not get invoked explicitly by any external minting methods in this contract and are only overwritten to satisfy
     *  the compiler
     */

    /** @notice overriding erc721 and erc721psi _safemint, super calls the `_safeMint` method of
     *  the erc721 implementation due to inheritance linearisation. Refer to erc721
     */
    function _safeMint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        super._safeMint(to, tokenId);
    }

    /** @notice overriding erc721 and erc721psi _safemint, super calls the `_safeMint` method of
     *  the erc721 implementation due to inheritance linearisation. Refer to erc721
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual override(ERC721, ERC721Psi) {
        super._safeMint(to, tokenId, _data);
    }

    /** @notice overriding erc721 and erc721psi _safemint, super calls the `_mint` method of
     *  the erc721 implementation due to inheritance linearisation. Refer to erc721
     */
    function _mint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Psi) {
        super._mint(to, tokenId);
    }

    /** @notice refer to erc721 or erc721psi */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual override(ERC721, ERC721Psi) returns (bool) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._isApprovedOrOwner(spender, tokenId);
        }
        return ERC721Psi._isApprovedOrOwner(spender, tokenId);
    }

    /** @notice refer to erc721 or erc721psi */
    function _exists(uint256 tokenId) internal view virtual override(ERC721, ERC721PsiBurnable) returns (bool) {
        if (tokenId < mintBatchByQuantityThreshold()) {
            return ERC721._ownerOf(tokenId) != address(0) && (!_burnedTokens.get(tokenId));
        }
        return ERC721PsiBurnable._exists(tokenId);
    }

    /// @notice returns the startTokenID for the minting by quantity section of the contract
    function _startTokenId() internal pure virtual override(ERC721Psi) returns (uint256) {
        return mintBatchByQuantityThreshold();
    }

    /**
     * @inheritdoc ERC721
     */
    function _baseURI() internal view virtual override(ERC721, ERC721Psi) returns (string memory) {
        return ERC721._baseURI();
    }

}