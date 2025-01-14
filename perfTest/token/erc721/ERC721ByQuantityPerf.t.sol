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


    function testExists1() public {
        uint256 gasStart = gasleft();
        erc721BQ.exists(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("exists (first): ", gasStart - gasEnd);
    }
    function testExists2() public {
        uint256 gasStart = gasleft();
        erc721BQ.exists(lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("exists (last):  ", gasStart - gasEnd);
    }

    function testSafeMintByQuantity() public {
        uint256 gasUsed = mintByQuantity(10);
        emit log_named_uint("safeMintByQuantity    (10) gas: ", gasUsed);
        gasUsed = mintByQuantity(100);
        emit log_named_uint("safeMintByQuantity   (100) gas: ", gasUsed);
        gasUsed = mintByQuantity(1000);
        emit log_named_uint("safeMintByQuantity  (1000) gas: ", gasUsed);
        gasUsed = mintByQuantity(5000);
        emit log_named_uint("safeMintByQuantity  (5000) gas: ", gasUsed);
        gasUsed = mintByQuantity(10000);
        emit log_named_uint("safeMintByQuantity (10000) gas: ", gasUsed);
        gasUsed = mintByQuantity(15000);
        emit log_named_uint("safeMintByQuantity (15000) gas: ", gasUsed);
    }

    function testSafeMintByQuantity2() public {
        uint256 quantity = 1000;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, quantity);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity (1000) gas: ", gasStart - gasEnd);
    }

    function testSafeMintByQuantity3() public {
        uint256 quantity = 10000;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, quantity);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity (10000) gas: ", gasStart - gasEnd);
    }

    function testSafeMintByQuantity4() public {
        // 15000 results in 29,557,863 gas.
        uint256 quantity = 15000;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, quantity);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMintByQuantity (15000) gas: ", gasStart - gasEnd);
    }
    function mintByQuantity(uint256 _quantity) public returns(uint256) {
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, _quantity);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
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
