// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IImmutableERC721, IImmutableERC721Errors} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {ImmutableERC721MintByIDUpgradeableV3} from "../../../contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";
import {ImmutableERC721MintByIDBootstrapV3} from "../../../contracts/token/erc721/preset/ImmutableERC721MintByIDBootstrapV3.sol";
import {ERC721BaseTest} from "./ERC721Base.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC721/ERC721Upgradeable.sol";


contract ERC721BootstrapTest is ERC721BaseTest {
    ImmutableERC721MintByIDUpgradeableV3 erc721Impl;
    ImmutableERC721MintByIDBootstrapV3 bootstrap;
    ERC1967Proxy public proxy;

    function setUp() public virtual override {
        super.setUp();

       ImmutableERC721MintByIDBootstrapV3 bootstrapImpl = new ImmutableERC721MintByIDBootstrapV3();
       erc721Impl = new ImmutableERC721MintByIDUpgradeableV3();

        bytes memory initData = abi.encodeWithSelector(
            ImmutableERC721MintByIDUpgradeableV3.initialize.selector, 
            owner, name, symbol, baseURI, contractURI, address(allowlist), feeReceiver, feeNumerator
        );
        proxy = new ERC1967Proxy(address(bootstrapImpl), initData);

        erc721 = IImmutableERC721(address(proxy));
        bootstrap = ImmutableERC721MintByIDBootstrapV3(address(proxy));

        vm.prank(owner);
        bootstrap.grantMinterRole(minter);
    }



    function testEverything() public {
        // Mint some NFTs
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](2);
        uint256[] memory tokenIds1 = new uint256[](3);
        tokenIds1[0] = 3;
        tokenIds1[1] = 4;
        tokenIds1[2] = 5;
        uint256[] memory tokenIds2 = new uint256[](2);
        tokenIds2[0] = 6;
        tokenIds2[1] = 7;
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        mintRequests[1].to = user2;
        mintRequests[1].tokenIds = tokenIds2;
        vm.prank(minter);
        erc721.mintBatch(mintRequests);

        // Check the minting
        assertEq(erc721.balanceOf(user1), 3);
        assertEq(erc721.balanceOf(user2), 2);
        assertEq(erc721.totalSupply(), 5);
        assertEq(erc721.ownerOf(3), user1);
        assertEq(erc721.ownerOf(4), user1);
        assertEq(erc721.ownerOf(5), user1);
        assertEq(erc721.ownerOf(6), user2);
        assertEq(erc721.ownerOf(7), user2);

        // Change ownership of some NFTs
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[] memory requests = new ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[](2);
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest memory request1 = ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest({
            from: user1,
            to: user3,
            tokenId: 4
        });
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest memory request2 = ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest({
            from: user2,
            to: user3,
            tokenId: 7
        });
        requests[0] = request1;
        requests[1] = request2;
        
        vm.prank(owner);
        bootstrap.bootstrapPhaseChangeOwnership(requests);

        assertEq(erc721.balanceOf(user1), 2, "Balance user1 after change ownership");
        assertEq(erc721.balanceOf(user2), 1, "Balance user2 after change ownership");
        assertEq(erc721.balanceOf(user3), 2, "Balance user3 after change ownership");
        assertEq(erc721.totalSupply(), 5, "Total supply");
        assertEq(erc721.ownerOf(3), user1, "ownerOf 3");
        assertEq(erc721.ownerOf(4), user3, "ownerOf 4");
        assertEq(erc721.ownerOf(5), user1, "ownerOf 5");
        assertEq(erc721.ownerOf(6), user2, "ownerOf 6");
        assertEq(erc721.ownerOf(7), user3, "ownerOf 7");

        // Execute upgrade
        // A function must be called, so just call the balanceOf view function.
        bytes memory initData = abi.encodeWithSelector(ERC721Upgradeable.balanceOf.selector, address(1));
        vm.prank(owner);
        bootstrap.upgradeToAndCall(address(erc721Impl), initData);
        assertEq(bootstrap.version(), 1, "version");

        // Check ownership with upgraded
        assertEq(erc721.balanceOf(user1), 2, "Balance user1 after upgrade");
        assertEq(erc721.balanceOf(user2), 1, "Balance user2 after upgrade");
        assertEq(erc721.balanceOf(user3), 2, "Balance user3 after upgrade");
        assertEq(erc721.totalSupply(), 5, "Total supply after upgrade");
        assertEq(erc721.ownerOf(3), user1, "ownerOf 3 after upgrade");
        assertEq(erc721.ownerOf(4), user3, "ownerOf 4 after upgrade");
        assertEq(erc721.ownerOf(5), user1, "ownerOf 5 after upgrade");
        assertEq(erc721.ownerOf(6), user2, "ownerOf 6 after upgrade");
        assertEq(erc721.ownerOf(7), user3, "ownerOf 7 after upgrade");
    }


    function notOwnedRevertError(uint256 /* _tokenIdToBeBurned */) public pure override returns (bytes memory) {
        return "ERC721: caller is not token owner or approved";
    }
}