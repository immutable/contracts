// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @notice Interface for Immutable's ERC1155
 */
interface IImmutableERC1155 is IERC1155 {
    /**
     * @notice Mints a new token
     * @param to The address that will receive the minted tokens
     * @param id The id of the token to mint
     * @param value The amount of tokens to mint
     * @param data Additional data
     */
    function safeMint(address to, uint256 id, uint256 value, bytes memory data) external;

    /**
     * @notice Grants minter role to the user
     * @param user The address to grant the MINTER_ROLE to
     */
    function grantMinterRole(address user) external;
}
