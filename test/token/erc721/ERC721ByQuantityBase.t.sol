// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ERC721BaseTest} from "./ERC721Base.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";


/**
 * Base contract for all ERC 721 by quantity tests.
 */
abstract contract ERC721ByQuantityBaseTest is ERC721BaseTest {
    IImmutableERC721ByQuantity public erc721BQ;

    function setUp() public virtual override {
        super.setUp();
    }
}
