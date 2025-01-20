// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721PerfTest} from "./ERC721Perf.t.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721Structs} from "../../../contracts/token/erc721/interfaces/IImmutableERC721Structs.sol";


/**
 * Contract for all ERC 721 by quantity perfromance tests.
 */
abstract contract ERC721ByQuantityPerfTest is ERC721PerfTest {
    IImmutableERC721ByQuantity public erc721BQ;

    function prefillWithNfts() public override {
        uint256 startId = 10000;

        for (uint256 i = 0; i < 150; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }
    }



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

    function testMintByQuantity() public {
        uint256 gasUsed = mintByQuantity(10);
        emit log_named_uint("mintByQuantity    (10) gas: ", gasUsed);
        gasUsed = mintByQuantity(100);
        emit log_named_uint("mintByQuantity   (100) gas: ", gasUsed);
        gasUsed = mintByQuantity(1000);
        emit log_named_uint("mintByQuantity  (1000) gas: ", gasUsed);
        gasUsed = mintByQuantity(5000);
        emit log_named_uint("mintByQuantity  (5000) gas: ", gasUsed);
        gasUsed = mintByQuantity(10000);
        emit log_named_uint("mintByQuantity (10000) gas: ", gasUsed);
        gasUsed = mintByQuantity(15000);
        emit log_named_uint("mintByQuantity (15000) gas: ", gasUsed);
    }
    function mintByQuantity(uint256 _quantity) public returns(uint256) {
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.mintByQuantity(user3, _quantity);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testSafeMintByQuantity() public {
        uint256 gasUsed = safeMintByQuantity(10);
        emit log_named_uint("safeMintByQuantity    (10) gas: ", gasUsed);
        gasUsed = safeMintByQuantity(100);
        emit log_named_uint("safeMintByQuantity   (100) gas: ", gasUsed);
        gasUsed = safeMintByQuantity(1000);
        emit log_named_uint("safeMintByQuantity  (1000) gas: ", gasUsed);
        gasUsed = safeMintByQuantity(5000);
        emit log_named_uint("safeMintByQuantity  (5000) gas: ", gasUsed);
        gasUsed = safeMintByQuantity(10000);
        emit log_named_uint("safeMintByQuantity (10000) gas: ", gasUsed);
        gasUsed = safeMintByQuantity(15000);
        emit log_named_uint("safeMintByQuantity (15000) gas: ", gasUsed);
    }

    function safeMintByQuantity(uint256 _quantity) public returns(uint256) {
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(user3, _quantity);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testMintBatchByQuantity() public {
        uint256 gasUsed = mintBatchByQuantity(10);
        emit log_named_uint("mintBatchByQuantity    (10x10) gas: ", gasUsed);
        gasUsed = mintBatchByQuantity(100);
        emit log_named_uint("mintBatchByQuantity  (100x100) gas: ", gasUsed);
    }
    function mintBatchByQuantity(uint256 _quantity) public returns(uint256) {
        IImmutableERC721Structs.Mint[] memory mints = new IImmutableERC721Structs.Mint[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            IImmutableERC721Structs.Mint memory mint = IImmutableERC721Structs.Mint(user1, _quantity);
            mints[i] = mint;
        }
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.mintBatchByQuantity(mints);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testSafeMintBatchByQuantity() public {
        uint256 gasUsed = safeMintBatchByQuantity(10);
        emit log_named_uint("safeMintBatchByQuantity    (10x10) gas: ", gasUsed);
        gasUsed = safeMintBatchByQuantity(100);
        emit log_named_uint("safeMintBatchByQuantity  (100x100) gas: ", gasUsed);
    }
    function safeMintBatchByQuantity(uint256 _quantity) public returns(uint256) {
        IImmutableERC721Structs.Mint[] memory mints = new IImmutableERC721Structs.Mint[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            IImmutableERC721Structs.Mint memory mint = IImmutableERC721Structs.Mint(user1, _quantity);
            mints[i] = mint;
        }
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721BQ.safeMintBatchByQuantity(mints);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testTotalSupply3() public {
        uint256 startId = 100000000;
        for (uint256 i = 0; i < 20; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }

        uint256 gasStart = gasleft();
        uint256 supply = erc721.totalSupply();
        uint256 gasEnd = gasleft();
        emit log_named_uint("totalSupply", supply);
        emit log_named_uint("totalSupply gas", gasStart - gasEnd);
    }

    function testTotalSupply4() public {
        uint256 startId = 100000000;
        for (uint256 i = 0; i < 30; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }

        uint256 gasStart = gasleft();
        uint256 supply = erc721.totalSupply();
        uint256 gasEnd = gasleft();
        emit log_named_uint("totalSupply", supply);
        emit log_named_uint("totalSupply gas", gasStart - gasEnd);
    }

    function mintLots(address _recipient, uint256, uint256 _quantity) public override returns (uint256) {
        vm.recordLogs();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(_recipient, _quantity);
        return findFirstNftId();
    }
}
