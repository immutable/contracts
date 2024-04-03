// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

pragma solidity ^0.8.17;

import {ReceivedItem, SpentItem, ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ImmutableSignedZoneV2} from "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";
import {ImmutableSignedZoneV2TestHelper} from "./ImmutableSignedZoneV2TestHelper.t.sol";

/* solhint-disable func-name-mixedcase */

contract ImmutableSignedZoneV2Test is ImmutableSignedZoneV2TestHelper {
    event SeaportCompatibleContractDeployed(); // SIP-5
    event SignerAdded(address signer); // SIP-7
    event SignerRemoved(address signer); // SIP-7

    error SignerCannotBeZeroAddress(); // SIP-7
    error SignerAlreadyActive(address signer); // SIP-7
    error SignerCannotBeReauthorized(address signer); // SIP-7
    error SignerNotActive(address signer); // SIP-7
    error InvalidExtraData(string reason, bytes32 orderHash); // SIP-7
    error SubstandardViolation(uint256 substandardId, string reason, bytes32 orderHash); // SIP-7 (custom)

    /* constructor */

    function test_contructor_grantsAdminRoleToOwner() public {
        address owner = makeAddr("owner");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        bool ownerHasAdminRole = zone.hasRole(zone.DEFAULT_ADMIN_ROLE(), owner);
        assertTrue(ownerHasAdminRole);
    }

    function test_contructor_emitsSeaportCompatibleContractDeployedEvent() public {
        vm.expectEmit();
        emit SeaportCompatibleContractDeployed();
        new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            makeAddr("owner")
        );
    }

    /* addSigner - L */

    function test_addSigner_revertsIfCalledByNonAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone();
        vm.expectRevert(
            "AccessControl: account 0x42a3d6e125aad539ac15ed04e1478eb0a4dc1489 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        vm.prank(makeAddr("random"));
        zone.addSigner(makeAddr("signerToAdd"));
    }

    function test_addSigner_revertsIfSignerIsTheZeroAddress() public {
        ImmutableSignedZoneV2 zone = _newZone();
        vm.expectRevert(abi.encodeWithSelector(SignerCannotBeZeroAddress.selector));
        vm.prank(OWNER);
        zone.addSigner(address(0));
    }

    function test_addSigner_emitsSignerAddedEvent() public {
        address owner = makeAddr("owner");
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.expectEmit(address(zone));
        emit SignerAdded(signerToAdd);
        vm.prank(owner);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerAlreadyActive() public {
        address owner = makeAddr("owner");
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.prank(owner);
        zone.addSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerAlreadyActive.selector, signerToAdd));
        vm.prank(owner);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerWasPreviouslyActive() public {
        address owner = makeAddr("owner");
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.prank(owner);
        zone.addSigner(signerToAdd);
        vm.prank(owner);
        zone.removeSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerCannotBeReauthorized.selector, signerToAdd));
        vm.prank(owner);
        zone.addSigner(signerToAdd);
    }

    /* removeSigner - L */

    function test_removeSigner_revertsIfCalledByNonAdminRole() public {
        address owner = makeAddr("owner");
        address randomAddress = makeAddr("random");
        address signerToRemove = makeAddr("signerToRemove");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.expectRevert(
            "AccessControl: account 0x42a3d6e125aad539ac15ed04e1478eb0a4dc1489 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        vm.prank(randomAddress);
        zone.removeSigner(signerToRemove);
    }

    function test_removeSigner_revertsIfSignerNotActive() public {
        address owner = makeAddr("owner");
        address signerToRemove = makeAddr("signerToRemove");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.expectRevert(abi.encodeWithSelector(SignerNotActive.selector, signerToRemove));
        vm.prank(owner);
        zone.removeSigner(signerToRemove);
    }

    function test_removeSigner_emitsSignerRemovedEvent() public {
        address owner = makeAddr("owner");
        address signerToRemove = makeAddr("signerToRemove");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        vm.prank(owner);
        zone.addSigner(signerToRemove);
        vm.expectEmit(address(zone));
        emit SignerRemoved(signerToRemove);
        vm.prank(owner);
        zone.removeSigner(signerToRemove);
    }

    /* updateAPIEndpoint - N */

    /* getSeaportMetadata - L */

    /* sip7Information - L */

    /* supportsInterface - L */

    /* validateOrder */

    /* _getSupportedSubstandards - L */

    /* _deriveSignedOrderHash - N  */

    /* _validateSubstandards */

    /* _validateSubstandard3 */

    function test_validateSubstandard3_returnsZeroLengthIfNotSubstandard3() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        bytes memory context = new bytes(0x04);
        uint256 substandardLengthResult = zone.exposed_validateSubstandard3(context, zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard3_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        bytes memory context = abi.encodePacked(bytes1(0x03), bytes10(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector,
                "invalid context, expecting substandard ID 3 followed by bytes32 consideration hash",
                zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard3(context, zoneParameters);
    }

    function test_validateSubstandard3_revertsIfDerivedReceivedItemsHashNotEqualToHashInContext() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ReceivedItem[] memory consideration = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 222,
            amount: 1,
            recipient: payable(address(0x3))
        });
        consideration[0] = receivedItem;
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: consideration,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        bytes memory context = abi.encodePacked(bytes1(0x03), bytes32(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                SubstandardViolation.selector, 3, "invalid consideration hash", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard3(context, zoneParameters);
    }

    function test_validateSubstandard3_returns33OnSuccess() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ReceivedItem[] memory consideration = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 222,
            amount: 1,
            recipient: payable(address(0x3))
        });
        consideration[0] = receivedItem;
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: consideration,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(consideration, 1, 1));
        bytes32 substandard3Data = bytes32(0x9062b0574be745508bed2ff7f8f5057446b89d16d35980b2a26f8e4cb03ddf91);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data);
        uint256 substandardLengthResult = zone.exposed_validateSubstandard3(context, zoneParameters);
        assertEq(substandardLengthResult, 33);
    }

    /* _validateSubstandard4 - N */

    function test_validateSubstandard4_returnsZeroLengthIfNotSubstandard4() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        bytes memory context = new bytes(0x04);
        uint256 substandardLengthResult = zone.exposed_validateSubstandard4(context, zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard4_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        bytes memory context = abi.encodePacked(bytes1(0x04), bytes10(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector,
                "invalid context, expecting substandard ID 4 followed by bytes32 array offset and bytes32 array length",
                zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard4(context, zoneParameters);
    }

    function test_validateSubstandard4_revertsIfDerivedOrderHashesIsNotEqualToHashesInContext() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x04), bytes32(uint256(32)), bytes32(uint256(1)), bytes32(0x0));
        vm.expectRevert(
            abi.encodeWithSelector(SubstandardViolation.selector, 4, "invalid order hashes", zoneParameters.orderHash)
        );
        zone.exposed_validateSubstandard4(context, zoneParameters);
    }

    function test_validateSubstandard4_returnsLengthOfSubstandardSegmentOnSuccess() public {
        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            address(0x2)
        );
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(
            bytes1(0x04),
            bytes32(uint256(32)),
            bytes32(uint256(1)),
            bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9)
        );
        uint256 substandardLengthResult = zone.exposed_validateSubstandard4(context, zoneParameters);
        // bytes1 + bytes32 + bytes32 + bytes32 = 97
        assertEq(substandardLengthResult, 97);
    }

    /* _validateSubstandard6 - N */

    /* _deriveReceivedItemsHash - N */

    /* _bytes32ArrayIncludes - N */

    /* _domainSeparator - N */

    /* _deriveDomainSeparator - N */
}
