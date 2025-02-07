// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {ERC721OperationalByQuantityBaseTest} from "./ERC721OperationalByQuantityBase.t.sol";
import {ImmutableERC721V2} from "../../../contracts/token/erc721/preset/ImmutableERC721V2.sol";
import {IImmutableERC721ByQuantity} from "../../../contracts/token/erc721/interfaces/IImmutableERC721ByQuantity.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";


// Test the original ImmutableERC721 contract: Operational tests
contract ERC721OperationalByQuantityV2Test is ERC721OperationalByQuantityBaseTest {
    ImmutableERC721V2 erc721BQv2;

    function setUp() public virtual override {
        super.setUp();

        erc721BQv2 = new ImmutableERC721V2(
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, feeNumerator
        );

        // ImmutableERC721 does not implement the interface, and hence must be cast to the 
        // interface type.
        erc721BQ = IImmutableERC721ByQuantity(address(erc721BQv2));
        erc721 = IImmutableERC721(address(erc721BQv2));

        vm.prank(owner);
        erc721.grantMinterRole(minter);
   }


    function testMintBatchByQuantityNextTokenId() public {
        uint256 nextId = erc721BQv2.mintBatchByQuantityNextTokenId();
        require(nextId == getFirst(), "First");

        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, 1);
        uint256 newNextId = erc721BQv2.mintBatchByQuantityNextTokenId();
        require(newNextId == nextId + 256, "After first mint");
        nextId = newNextId;

        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, 256);
        newNextId = erc721BQv2.mintBatchByQuantityNextTokenId();
        require(newNextId == nextId + 256, "After second mint");
        nextId = newNextId;

        vm.prank(minter);
        erc721BQ.mintByQuantity(user1, 257);
        newNextId = erc721BQv2.mintBatchByQuantityNextTokenId();
        require(newNextId == nextId + 512, "After third mint");
    }

    function notOwnedRevertError(uint256 _tokenIdToBeBurned) public pure override returns (bytes memory) {
        return abi.encodeWithSelector(IImmutableERC721Errors.IImmutableERC721NotOwnerOrOperator.selector, _tokenIdToBeBurned);
    }

    function getFirst() internal override view returns (uint256) {
        uint256 nominalFirst = erc721BQ.mintBatchByQuantityThreshold();
        return ((nominalFirst / 256) + 1) * 256;
    }

}