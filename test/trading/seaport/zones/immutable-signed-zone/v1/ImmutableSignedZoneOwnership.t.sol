// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ImmutableSignedZone} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";



contract ImmutableSignedZoneOwnershipTest is Test {
    ImmutableSignedZone public zone;
    address public owner;
    address public user;

    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Deploy contract
        vm.startPrank(owner);
        zone = new ImmutableSignedZone("ImmutableSignedZone", "", "", owner);
        vm.stopPrank();
    }

    function testDeployerBecomesOwner() public view {
        assertEq(zone.owner(), owner);
    }

    function testTransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        
        vm.startPrank(owner);
        zone.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(zone.owner(), newOwner);
    }

    function testNonOwnerCannotTransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        zone.transferOwnership(newOwner);
        vm.stopPrank();
    }

    function testNonOwnerCannotAddSigner() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        zone.addSigner(user);
        vm.stopPrank();
    }

    function testNonOwnerCannotRemoveSigner() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        zone.removeSigner(user);
        vm.stopPrank();
    }
} 