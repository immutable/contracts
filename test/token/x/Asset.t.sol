// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Asset} from "../../../contracts/token/erc721/x/Asset.sol";

contract AssetTest is Test {
    Asset public asset;
    address public owner;
    address public imx;

    function setUp() public {
        owner = makeAddr("owner");
        imx = makeAddr("imx");
        vm.startPrank(owner);
        asset = new Asset(owner, "Gods Unchained", "GU", imx);
        vm.stopPrank();
    }

    function testMintWithValidBlueprint() public {
        uint256 tokenID = 123;
        string memory tokenIDStr = "123";
        string memory blueprint = "1000";
        bytes memory blob = abi.encodePacked("{", tokenIDStr, "}:{", blueprint, "}");

        vm.startPrank(imx);
        asset.mintFor(owner, 1, blob);
        vm.stopPrank();

        assertEq(asset.ownerOf(tokenID), owner, "Incorrect owner");
        assertEq(asset.blueprints(tokenID).length, bytes(blueprint).length, "Incorrect blueprint length");
        for (uint256 i = 0; i < bytes(blueprint).length; i++) {
            assertEq(asset.blueprints(tokenID)[i], bytes(blueprint)[i], "Incorrect blueprint");
        }
    }

    function testMintWithEmptyBlueprint() public {
        uint256 tokenID = 123;
        string memory tokenIDStr = "123";
        string memory blueprint = "";
        bytes memory blob = abi.encodePacked("{", tokenIDStr, "}:{", blueprint, "}");

        vm.startPrank(imx);
        asset.mintFor(owner, 1, blob);
        vm.stopPrank();

        assertEq(asset.ownerOf(tokenID), owner, "Incorrect owner");
        assertEq(asset.blueprints(tokenID).length, 0, "Incorrect blueprint length");
    }

    function testMintWithInvalidBlueprint() public {
        bytes memory separator = ":";
        bytes memory blob = separator;
        
        vm.startPrank(imx);
        vm.expectRevert();
        asset.mintFor(owner, 1, blob);
        vm.stopPrank();
    }
} 