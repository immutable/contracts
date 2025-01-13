// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IImmutableERC721} from "./IImmutableERC721.sol";

interface IImmutableERC721ByQuantity is IImmutableERC721 {
    /// @notice A singular Mint by quantity request
    struct Mint {
        address to;
        uint256 quantity;
    }

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a specified address
     *  @param to the address to mint the token to
     *  @param quantity the number of tokens to mint
     */
    function mintByQuantity(address to, uint256 quantity) external;

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a specified address with hooks
     *  and checks
     *  @param to the address to mint the token to
     *  @param quantity the number of tokens to mint
     */
    function safeMintByQuantity(address to, uint256 quantity) external;

    /**
     * @notice Allows minter to mint a number of tokens sequentially to a number of specified addresses
     *  @param mints the list of Mint struct containing the to, and the number of tokens to mint
     */
    function mintBatchByQuantity(Mint[] calldata mints) external;

    /**
     * @notice Allows minter to safe mint a number of tokens sequentially to a number of specified addresses
     *  @param mints the list of Mint struct containing the to, and the number of tokens to mint
     */
    function safeMintBatchByQuantity(Mint[] calldata mints) external;

    /**
     * @notice checks to see if tokenID exists in the collection
     *  @param tokenId the id of the token to check
     *
     */
    function exists(uint256 tokenId) external view returns (bool);
}
