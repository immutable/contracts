// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721BaseTest} from "../../../test/token/erc721/ERC721Base.t.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";


/**
 * Contract for all ERC 721 by quantity perfromance tests.
 */
abstract contract ERC721PerfTest is ERC721BaseTest {
    uint256 firstNftId = 0;
    uint256 lastNftId = 0;


    function setUp() public virtual override {
        setUpStart();
        setUpLastNft();
    }

    function setUpStart() public virtual {
        super.setUp();
    }

    /**
     * Allow this to be called separately as extending contracts might prefill 
     * the contract with lots of NFTs.
     */
    function setUpLastNft() public {
        uint256 startId = mintLots(user1, 1000000000, 15000);
        lastNftId = startId + 14999;
    }


    function testApprove() public {
        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.approve(user2, firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("approve gas (first): ", gasStart - gasEnd);

        gasStart = gasleft();
        vm.prank(user1);
        erc721.approve(user2, lastNftId);
        gasEnd = gasleft();
        emit log_named_uint("approve gas (last):  ", gasStart - gasEnd);
    }

    function testBalanceOf() public {
        uint256 gasStart = gasleft();
        erc721.balanceOf(user1);
        uint256 gasEnd = gasleft();
        emit log_named_uint("balanceOf user1: ", gasStart - gasEnd);

        gasStart = gasleft();
        erc721.balanceOf(user2);
        gasEnd = gasleft();
        emit log_named_uint("balanceOf user2:  ", gasStart - gasEnd);

        gasStart = gasleft();
        erc721.balanceOf(prefillUser1);
        gasEnd = gasleft();
        emit log_named_uint("balanceOf pref:  ", gasStart - gasEnd);
    }

    function testBurn() public {
        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.burn(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burn (first): ", gasStart - gasEnd);

        gasStart = gasleft();
        vm.prank(user1);
        erc721.burn(lastNftId);
        gasEnd = gasleft();
        emit log_named_uint("burn (last):  ", gasStart - gasEnd);
    }

    function testBurnWithApprove() public {
        vm.prank(prefillUser1);
        erc721.approve(user2, firstNftId);
        uint256 gasStart = gasleft();
        vm.prank(user2);
        erc721.burn(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burn (first): ", gasStart - gasEnd);

        vm.prank(user1);
        erc721.approve(user2, lastNftId);
        gasStart = gasleft();
        vm.prank(user2);
        erc721.burn(lastNftId);
        gasEnd = gasleft();
        emit log_named_uint("burn (last):  ", gasStart - gasEnd);
    }

    function testBurnBatch() public {
        uint256 first = mintLots(user3, 2000000000, 5000);

        uint256[] memory nfts = new uint256[](1500);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = first + 100 + i;
        }

        uint256 gasStart = gasleft();
        vm.prank(user3);
        erc721.burnBatch(nfts);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burnBatch: ", gasStart - gasEnd);
    }

    function testTotalSupply() public {
        uint256 gasStart = gasleft();
        erc721.totalSupply();
        uint256 gasEnd = gasleft();
        emit log_named_uint("totalSupply gas: ", gasStart - gasEnd);
    }

    function mintLots(address _recipient, uint256 _start, uint256 _quantity) public virtual returns (uint256) {
        uint256[] memory ids = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            ids[i] = i + _start;
        }
        vm.recordLogs();
        IImmutableERC721.IDMint memory mint = IImmutableERC721.IDMint(_recipient, ids);
        IImmutableERC721.IDMint[] memory mints = new IImmutableERC721.IDMint[](1);
        mints[0] = mint;
        vm.prank(minter);
        erc721.mintBatch(mints);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 firstId = uint256(entries[0].topics[3]);
        return firstId;
    }

    function prefillWithNfts() public {
        uint256 startId = 10000;

        for (uint256 i = 0; i < 100; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }
    }

}
