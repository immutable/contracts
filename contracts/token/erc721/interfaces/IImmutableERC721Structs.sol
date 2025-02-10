// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

interface IImmutableERC721Structs {
    /**
     * @notice A singular batch transfer request. The length of the tos and tokenIds must be matching
     *  batch transfers will transfer the specified ids to their matching address via index.
     *
     */
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

    /// @notice A singular Mint by id request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    /// @notice A singular Mint by quantity request
    struct Mint {
        address to;
        uint256 quantity;
    }
}
