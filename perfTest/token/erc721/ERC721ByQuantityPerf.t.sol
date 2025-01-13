// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721PerfTest} from "./ERC721Perf.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";


/**
 * Contract for all ERC 721 by quantity perfromance tests.
 */
abstract contract ERC721ByQuantityPerfTest is ERC721PerfTest {
    IImmutableERC721ByQuantity public erc721BQ;


    function testExists() public {
        uint256 gasStart = gasleft();
        erc721BQ.exists(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("exists (first): ", gasStart - gasEnd);

        gasStart = gasleft();
        erc721BQ.exists(lastNftId);
        gasEnd = gasleft();
        emit log_named_uint("exists (last):  ", gasStart - gasEnd);
    }

    function testSafeMintByQuantity() public {
        // 15000 results in 29,557,863 gas.
        uint256 quantity = 15000;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, quantity);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity gas: ", gasStart - gasEnd);
    }


    function mintLots(address _recipient, uint256, uint256 _quantity) public override returns (uint256) {
        vm.recordLogs();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(_recipient, _quantity);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 firstId = uint256(entries[0].topics[3]);
        return firstId;
    }


}
