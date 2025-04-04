// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";
import {ERC721ByQuantityPerfTest} from "./ERC721ByQuantityPerf.t.sol";
import {ImmutableERC721} from "../../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";

/**
 * Contract for ERC 721 by quantity performance tests, for ImmutableERC721.sol (that is, v1).
 */
contract ImmutableERC721ByQuantityPerfTest is ERC721ByQuantityPerfTest {
    function setUpStart() public virtual override {
        super.setUpStart();

        ImmutableERC721 immutableERC721 = new ImmutableERC721(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, feeNumerator
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721BQ = IImmutableERC721ByQuantity(address(immutableERC721));
        erc721 = IImmutableERC721(address(immutableERC721));

        vm.prank(owner);
        erc721.grantMinterRole(minter);

        // Mint the first NFT to prefillUser1
        vm.recordLogs();
        vm.prank(minter);
        erc721BQ.safeMintByQuantity(prefillUser1, 1);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // Expect 1 of
        // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        assertEq(entries.length, 1, "More logs than expected");
        firstNftId = uint256(entries[0].topics[3]);
        //emit log_named_bytes32("First NFT ID", bytes32(firstNftId));
   }
}
