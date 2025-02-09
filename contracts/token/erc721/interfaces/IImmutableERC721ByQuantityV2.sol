// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IImmutableERC721ByQuantity} from "./IImmutableERC721ByQuantity.sol";

interface IImmutableERC721ByQuantityV2 is IImmutableERC721ByQuantity {
    /**
     * @notice returns the next token id that will be minted for the first
     *  NFT in a call to mintByQuantity or safeMintByQuantity.
     */
    function mintBatchByQuantityNextTokenId() external pure returns (uint256);
}
