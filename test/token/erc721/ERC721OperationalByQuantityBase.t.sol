// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721OperationalBaseTest} from "./ERC721OperationalBase.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";


// Test the original ImmutableERC721 contract: Operational tests
abstract contract ERC721OperationalByQuantityBaseTest is ERC721OperationalBaseTest {
    IImmutableERC721ByQuantity public erc721BQ;

}