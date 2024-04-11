// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice Interface for Immutable's ERC721
 */
interface IImmutableERC721 is IERC721 {
    /** @notice Allows minter to mint `tokenID` to `to`
     *  @param to the address to mint the token to
     *  @param tokenID the ID of the token to mint
     */
    function safeMint(address to, uint256 tokenID) external;

    /** @notice Allows admin grant `user` `MINTER` role
     *  @param user The address to grant the `MINTER` role to
     */
    function grantMinterRole(address user) external;
}
