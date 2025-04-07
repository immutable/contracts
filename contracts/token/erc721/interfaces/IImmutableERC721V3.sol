// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IImmutableERC721} from "./IImmutableERC721.sol";

interface IImmutableERC721V3 is IImmutableERC721 {
    /**
     * @notice Version number of the storage variable layout.
     */
    function version() external view returns (uint256);
}
