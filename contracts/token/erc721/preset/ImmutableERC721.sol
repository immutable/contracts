pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import {ERC721Hybrid} from "../abstract/ERC721Hybrid.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MintingAccessControl} from "../abstract/MintingAccessControl.sol";
import {ImmutableERC721HybridBase} from "../abstract/ImmutableERC721HybridBase.sol";

contract ImmutableERC721 is ImmutableERC721HybridBase {
    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
     * Sets the royalty receiver and amount (this can not be changed once set)
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address royaltyReceiver_,
        uint96 feeNumerator_
    )
        ImmutableERC721HybridBase(
            owner_,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            operatorAllowlist_,
            royaltyReceiver_,
            feeNumerator_
        )
    {}

    /// @dev Allows minter to a token by ID to a specified address
    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mintByID(to, tokenId);
    }

    /// @dev Allows minter to a token by ID to a specified address with hooks and checks
    function safeMint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _safeMintByID(to, tokenId);
    }

    /// @dev Allows minter to a number of tokens sequentially to a specified address
    function mintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mintByQuantity(to, quantity);
    }

    /** @dev Allows minter to a number of tokens sequentially to a specified address with hooks
     *  and checks
     **/
    function safeMintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _safeMintByQuantity(to, quantity);
    }

    /// @dev Allows minter to a number of tokens sequentially to a number of specified addresses
    function mintBatchByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByQuantity(mints);
    }

    /** @dev Allows minter to a number of tokens sequentially to a number of specified
     *  addresses with hooks and checks
     **/
    function safeMintBatchByQuantity(Mint[] memory mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByQuantity(mints);
    }

    /// @dev Allows minter to a number of tokens by ID to a number of specified addresses
    function mintBatch(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByIDToMultiple(mints);
    }

    /** @dev Allows minter to a number of tokens by ID to a number of specified
     *  addresses with hooks and checks
     **/
    function safeMintBatch(IDMint[] memory mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByIDToMultiple(mints);
    }

    /// @dev Allows caller to a burn a number of tokens by ID from a specified address
    function safeBurnBatch(IDBurn[] memory burns) external {
        _safeBurnBatch(burns);
    }

    /** @dev Allows caller to a transfer a number of tokens by ID from a specified
     *  address to a number of specified addresses
     **/
    function safeTransferFromBatch(TransferRequest calldata tr) external {
        if (tr.tokenIds.length != tr.tos.length) {
            revert IImmutableERC721MismatchedTransferLengths();
        }

        for (uint i = 0; i < tr.tokenIds.length; i++) {
            safeTransferFrom(tr.from, tr.tos[i], tr.tokenIds[i]);
        }
    }
}
