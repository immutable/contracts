// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ReceivedItem, SpentItem, ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";

contract ImmutableSignedZoneV2Test is Test {
    event SeaportCompatibleContractDeployed(); // SIP-5
    error InvalidExtraData(string reason, bytes32 orderHash); // SIP-7
    error SubstandardViolation(uint256 substandardId, string reason, bytes32 orderHash); // SIP-7 (custom)

    function test_contructor_grantsAdminRoleToOwner() public {
        address owner = address(0x2);
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
            address(0x2)
        );
    }

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
                SubstandardViolation.selector,
                3,
                "invalid consideration hash",
                zoneParameters.orderHash
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
}

contract ImmutableSignedZoneV2Harness is ImmutableSignedZoneV2 {
    constructor(
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        address owner
    ) ImmutableSignedZoneV2(zoneName, apiEndpoint, documentationURI, owner) {}

    function exposed_getSupportedSubstandards() external pure returns (uint256[] memory substandards) {
        return _getSupportedSubstandards();
    }

    function exposed_deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) external view returns (bytes32 signedOrderHash) {
        return _deriveSignedOrderHash(fulfiller, expiration, orderHash, context);
    }

    function exposed_validateSubstandards(
        bytes calldata context,
        ZoneParameters calldata zoneParameters
    ) external pure {
        return _validateSubstandards(context, zoneParameters);
    }

    function exposed_validateSubstandard3(
        bytes calldata context,
        ZoneParameters calldata zoneParameters
    ) external pure returns (uint256) {
        return _validateSubstandard3(context, zoneParameters);
    }

    function exposed_validateSubstandard4(
        bytes calldata context,
        ZoneParameters calldata zoneParameters
    ) external pure returns (uint256) {
        return _validateSubstandard4(context, zoneParameters);
    }

    function exposed_validateSubstandard6(
        bytes calldata context,
        ZoneParameters calldata zoneParameters
    ) external pure returns (uint256) {
        return _validateSubstandard6(context, zoneParameters);
    }

    function exposed_deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems,
        uint256 scalingFactorNumerator,
        uint256 scalingFactorDenominator
    ) external pure returns (bytes32) {
        return _deriveReceivedItemsHash(receivedItems, scalingFactorNumerator, scalingFactorDenominator);
    }

    function exposed_bytes32ArrayIncludes(
        bytes32[] calldata sourceArray,
        bytes32[] memory values
    ) external pure returns (bool) {
        return _bytes32ArrayIncludes(sourceArray, values);
    }

    function exposed_domainSeparator() external view returns (bytes32) {
        return _domainSeparator();
    }

    function exposed_deriveDomainSeparator() external view returns (bytes32 domainSeparator) {
        return _deriveDomainSeparator();
    }
}
