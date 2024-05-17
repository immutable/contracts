// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {ImmutableERC721HybridBase} from "../abstract/ImmutableERC721HybridBase.sol";

contract ImmutableERC721 is ImmutableERC721HybridBase {
    ///     =====   Constructor  =====

    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param royaltyReceiver_ The address of the royalty receiver
     * @param feeNumerator_ The royalty fee numerator
     * @dev the royalty receiver and amount (this can not be changed once set)
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

    /**
     * @notice Allows minter to mint a token by ID to a specified address
     *  @param to the address to mint the token to
     *  @param tokenId the ID of the token to mint
     */
    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mintByID(to, tokenId);
    }

    /**
     * @notice Allows minter to mint a token by ID to a specified address with hooks and checks
     *  @param to the address to mint the token to
     *  @param tokenId the ID of the token to mint
     */
    function safeMint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _safeMintByID(to, tokenId);
    }

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a specified address
     *  @param to the address to mint the token to
     *  @param quantity the number of tokens to mint
     */
    function mintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mintByQuantity(to, quantity);
    }

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a specified address with hooks
     *  and checks
     *  @param to the address to mint the token to
     *  @param quantity the number of tokens to mint
     */
    function safeMintByQuantity(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _safeMintByQuantity(to, quantity);
    }

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a number of specified addresses
     *  @param mints the list of Mint struct containing the to, and the number of tokens to mint
     */
    function mintBatchByQuantity(Mint[] calldata mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByQuantity(mints);
    }

    /**
     * @notice Allows minter to safe mint a number of tokens sequentially to a number of specified addresses
     *  @param mints the list of Mint struct containing the to, and the number of tokens to mint
     */
    function safeMintBatchByQuantity(Mint[] calldata mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByQuantity(mints);
    }

    /**
     * @notice Allows minter to safe mint a number of tokens by ID to a number of specified
     *  addresses with hooks and checks. Check ERC721Hybrid for details on _mintBatchByIDToMultiple
     *  @param mints the list of IDMint struct containing the to, and tokenIds
     */
    function mintBatch(IDMint[] calldata mints) external onlyRole(MINTER_ROLE) {
        _mintBatchByIDToMultiple(mints);
    }

    /**
     * @notice Allows minter to safe mint a number of tokens by ID to a number of specified
     *  addresses with hooks and checks. Check ERC721Hybrid for details on _safeMintBatchByIDToMultiple
     *  @param mints the list of IDMint struct containing the to, and tokenIds
     */
    function safeMintBatch(IDMint[] calldata mints) external onlyRole(MINTER_ROLE) {
        _safeMintBatchByIDToMultiple(mints);
    }

    /**
     * @notice Allows caller to a burn a number of tokens by ID from a specified address
     *  @param burns the IDBurn struct containing the to, and tokenIds
     */
    function safeBurnBatch(IDBurn[] calldata burns) external {
        _safeBurnBatch(burns);
    }

    /**
     * @notice Allows caller to a transfer a number of tokens by ID from a specified
     *  address to a number of specified addresses
     *  @param tr the TransferRequest struct containing the from, tos, and tokenIds
     */
    function safeTransferFromBatch(TransferRequest calldata tr) external {
        if (tr.tokenIds.length != tr.tos.length) {
            revert IImmutableERC721MismatchedTransferLengths();
        }

        for (uint256 i = 0; i < tr.tokenIds.length; i++) {
            safeTransferFrom(tr.from, tr.tos[i], tr.tokenIds[i]);
        }
    }
}
