// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ImmutableSignedZone} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";

contract ImmutableSignedZoneSignerManagementTest is Test {
    ImmutableSignedZone public zone;
    address public owner;
    address public signer;

    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        signer = makeAddr("signer");

        // Deploy contract
        vm.startPrank(owner);
        zone = new ImmutableSignedZone("ImmutableSignedZone", "", "", owner);
        vm.stopPrank();
    }

    function testOwnerCanAddActiveSigner() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit SIP7EventsAndErrors.SignerAdded(signer);
        zone.addSigner(signer);
        vm.stopPrank();
    }

    function testOwnerCanAddAndRemoveActiveSigner() public {
        vm.startPrank(owner);
        zone.addSigner(signer);
        
        vm.expectEmit(true, true, true, true);
        emit SIP7EventsAndErrors.SignerRemoved(signer);
        zone.removeSigner(signer);
        vm.stopPrank();
    }

    function testCannotAddDeactivatedSigner() public {
        vm.startPrank(owner);
        zone.addSigner(signer);
        zone.removeSigner(signer);
        
        // Try to add deactivated signer
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerCannotBeReauthorized.selector, signer));
        zone.addSigner(signer);
        vm.stopPrank();
    }

    function testAlreadyActiveSignerCannotBeAdded() public {
        vm.startPrank(owner);
        zone.addSigner(signer);
        
        // Try to add same signer again
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerAlreadyActive.selector, signer));
        zone.addSigner(signer);
        vm.stopPrank();
    }
} 