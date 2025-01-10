// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721ByQuantityBaseTest} from "./ERC721ByQuantityBase.t.sol";


/**
 * Contract for all ERC 721 by quantity perfromance tests.
 */
abstract contract ERC721ByQuantityPerfTest is ERC721ByQuantityBaseTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test() public {
        
        uint256 quantity = 5200;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user1, quantity);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity1 gas: ", gasStart - gasEnd);

        gasStart = gasleft();
        uint256 bal = erc721BQ.balanceOf(user1);
        gasEnd = gasleft();
        assertEq(quantity, bal, "Balance incorrect1");
        emit log_named_uint("balanceOf1 gas: ", gasStart - gasEnd);

        uint256 moreQuantity = 200;
        gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user1, moreQuantity);
        gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity2 gas: ", gasStart - gasEnd);

        gasStart = gasleft();
        bal = erc721BQ.balanceOf(user1);
        gasEnd = gasleft();
        assertEq(quantity + moreQuantity, bal, "Balance incorrect2");
        emit log_named_uint("balanceOf2 gas: ", gasStart - gasEnd);
    }


}
