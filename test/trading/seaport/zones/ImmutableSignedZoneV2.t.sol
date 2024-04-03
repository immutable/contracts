// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ReceivedItem, Schema, SpentItem, ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ImmutableSignedZoneV2} from "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";
import {ImmutableSignedZoneV2TestHelper} from "./ImmutableSignedZoneV2TestHelper.t.sol";

// solhint-disable func-name-mixedcase

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
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = _newZone();
        vm.expectEmit(address(zone));
        emit SignerAdded(signerToAdd);
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerAlreadyActive() public {
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = _newZone();
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerAlreadyActive.selector, signerToAdd));
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerWasPreviouslyActive() public {
        address signerToAdd = makeAddr("signerToAdd");
        ImmutableSignedZoneV2 zone = _newZone();
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
        vm.prank(OWNER);
        zone.removeSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerCannotBeReauthorized.selector, signerToAdd));
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    /* removeSigner - L */

    function test_removeSigner_revertsIfCalledByNonAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone();
        vm.expectRevert(
            "AccessControl: account 0x42a3d6e125aad539ac15ed04e1478eb0a4dc1489 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        vm.prank(makeAddr("random"));
        zone.removeSigner(makeAddr("signerToRemove"));
    }

    function test_removeSigner_revertsIfSignerNotActive() public {
        address signerToRemove = makeAddr("signerToRemove");
        ImmutableSignedZoneV2 zone = _newZone();
        vm.expectRevert(abi.encodeWithSelector(SignerNotActive.selector, signerToRemove));
        vm.prank(OWNER);
        zone.removeSigner(signerToRemove);
    }

    function test_removeSigner_emitsSignerRemovedEvent() public {
        address signerToRemove = makeAddr("signerToRemove");
        ImmutableSignedZoneV2 zone = _newZone();
        vm.prank(OWNER);
        zone.addSigner(signerToRemove);
        vm.expectEmit(address(zone));
        emit SignerRemoved(signerToRemove);
        vm.prank(OWNER);
        zone.removeSigner(signerToRemove);
    }

    /* updateAPIEndpoint - N */

    /* getSeaportMetadata - L */

    function test_getSeaportMetadata() public {
        string memory expectedZoneName = "MyZoneName";
        string memory expectedApiEndpoint = "https://www.immutable.com";
        string memory expectedDocumentationURI = "https://www.immutable.com/docs";

        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            expectedZoneName,
            expectedApiEndpoint,
            expectedDocumentationURI,
            OWNER
        );

        bytes32 expectedDomainSeparator = zone.exposed_deriveDomainSeparator();
        uint256[] memory expectedSubstandards = zone.exposed_getSupportedSubstandards();

        (string memory name, Schema[] memory schemas) = zone.getSeaportMetadata();
        (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        ) = abi.decode(schemas[0].metadata, (bytes32, string, uint256[], string));
        assertEq(name, expectedZoneName);
        assertEq(schemas.length, 1);
        assertEq(schemas[0].id, 7);
        assertEq(domainSeparator, expectedDomainSeparator);
        assertEq(apiEndpoint, expectedApiEndpoint);
        assertEq(substandards, expectedSubstandards);
        assertEq(documentationURI, expectedDocumentationURI);
    }

    /* sip7Information - L */

    function test_sip7Information() public {
        string memory expectedApiEndpoint = "https://www.immutable.com";
        string memory expectedDocumentationURI = "https://www.immutable.com/docs";

        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            expectedApiEndpoint,
            expectedDocumentationURI,
            OWNER
        );

        bytes32 expectedDomainSeparator = zone.exposed_deriveDomainSeparator();
        uint256[] memory expectedSubstandards = zone.exposed_getSupportedSubstandards();

        (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        ) = zone.sip7Information();
        assertEq(domainSeparator, expectedDomainSeparator);
        assertEq(apiEndpoint, expectedApiEndpoint);
        assertEq(substandards, expectedSubstandards);
        assertEq(documentationURI, expectedDocumentationURI);
    }

    /* supportsInterface - L */

    /* validateOrder */

    /* _getSupportedSubstandards - L */

    function test_getSupportedSubstandards() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        uint256[] memory supportedSubstandards = zone.exposed_getSupportedSubstandards();
        assertEq(supportedSubstandards.length, 3);
        assertEq(supportedSubstandards[0], 3);
        assertEq(supportedSubstandards[1], 4);
        assertEq(supportedSubstandards[2], 6);
    }

    /* _deriveSignedOrderHash - N  */

    /* _validateSubstandards */

    /* _validateSubstandard3 */

    function test_validateSubstandard3_returnsZeroLengthIfNotSubstandard3() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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

    function test_validateSubstandard6_returnsZeroLengthIfNotSubstandard6() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        uint256 substandardLengthResult = zone.exposed_validateSubstandard6(context, zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard6_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
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
        bytes memory context = abi.encodePacked(bytes1(0x06), bytes10(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector,
                "invalid context, expecting substandard ID 6 followed by (uint256, bytes32)",
                zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard6(context, zoneParameters);
    }

    function test_validateSubstandard6_revertsIfDerivedReceivedItemsHashesIsNotEqualToHashesInContext() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 222,
            amount: 1,
            recipient: payable(address(0x3))
        });
        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC721, token: address(0x2), identifier: 222, amount: 10});
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x06), uint256(100), bytes32(uint256(0x123456)));
        vm.expectRevert(
            abi.encodeWithSelector(
                SubstandardViolation.selector, 6, "invalid consideration hash", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard6(context, zoneParameters);
    }

    function test_validateSubstandard6_returnsLengthOfSubstandardSegmentOnSuccess() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 222,
            amount: 1,
            recipient: payable(address(0x3))
        });
        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC721, token: address(0x2), identifier: 222, amount: 10});
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10));
        bytes32 substandard6Data = 0xff3642433fc0f83e6d23869de6d358c7c36e3257da4bd89a3b6d17dd25e7c823;
        bytes memory context = abi.encodePacked(bytes1(0x06), uint256(100), substandard6Data);
        uint256 substandardLengthResult = zone.exposed_validateSubstandard6(context, zoneParameters);
        // bytes1 + uint256 + bytes32 = 65
        assertEq(substandardLengthResult, 65);
    }

    /* _deriveReceivedItemsHash - N */

    function test_deriveReceivedItemsHash_returnsHashIfNoReceivedItems() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        ReceivedItem[] memory receivedItems = new ReceivedItem[](0);
        bytes32 receivedItemsHash = zone.exposed_deriveReceivedItemsHash(receivedItems, 0, 0);
        assertEq(receivedItemsHash, bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470));
    }

    function test_deriveReceivedItemsHash_returnsHashForValidReceivedItems() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        ReceivedItem[] memory receivedItems = new ReceivedItem[](2);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 222,
            amount: 1,
            recipient: payable(address(0x3))
        });
        receivedItems[1] = ReceivedItem({
            itemType: ItemType.ERC721,
            token: address(0x2),
            identifier: 199,
            amount: 1,
            recipient: payable(address(0x3))
        });
        bytes32 receivedItemsHash = zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10);
        assertEq(receivedItemsHash, bytes32(0xf01bacf40a3dd95740faaaad186bf1c000a9edc06008ea07c789ea761d7f3ffb));
    }

    /* _bytes32ArrayIncludes - N */

    function test_bytes32ArrayIncludes_returnsFalseIfSourceArrayIsEmpty() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        bytes32[] memory emptySourceArray = new bytes32[](0);
        bytes32[] memory valuesArray = new bytes32[](2);
        bool includes = zone.exposed_bytes32ArrayIncludes(emptySourceArray, valuesArray);
        assertFalse(includes);
    }

    function test_bytes32ArrayIncludes_returnsFalseIfSourceArrayIsSmallerThanValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        bytes32[] memory sourceArray = new bytes32[](1);
        bytes32[] memory valuesArray = new bytes32[](2);
        bool includesEmptySource = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertFalse(includesEmptySource);
    }

    function test_bytes32ArrayIncludes_returnsFalseIfSourceArrayDoesNotIncludeValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        bytes32[] memory sourceArray = new bytes32[](2);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(3));
        valuesArray[1] = bytes32(uint256(4));
        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertFalse(includes);
    }

    function test_bytes32ArrayIncludes_returnsTrueIfSourceArrayIncludesValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        bytes32[] memory sourceArray = new bytes32[](2);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(1));
        valuesArray[1] = bytes32(uint256(2));
        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertTrue(includes);
    }

    function test_bytes32ArrayIncludes_returnsTrueIfValuesArrayIsASubsetOfSourceArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness();
        bytes32[] memory sourceArray = new bytes32[](4);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        sourceArray[2] = bytes32(uint256(3));
        sourceArray[3] = bytes32(uint256(4));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(1));
        valuesArray[1] = bytes32(uint256(2));
        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertTrue(includes);
    }

    /* _domainSeparator - N */

    /* _deriveDomainSeparator - N */
}

// solhint-enable func-name-mixedcase
