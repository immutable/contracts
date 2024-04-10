// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ReceivedItem, ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ImmutableSignedZoneV2} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/ImmutableSignedZoneV2.sol";

// solhint-disable func-name-mixedcase

contract ImmutableSignedZoneV2Harness is ImmutableSignedZoneV2 {
    constructor(string memory zoneName, string memory apiEndpoint, string memory documentationURI, address owner)
        ImmutableSignedZoneV2(zoneName, apiEndpoint, documentationURI, owner)
    {}

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

    function exposed_validateSubstandards(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
    {
        return _validateSubstandards(context, zoneParameters);
    }

    function exposed_validateSubstandard3(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
        returns (uint256)
    {
        return _validateSubstandard3(context, zoneParameters);
    }

    function exposed_validateSubstandard4(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
        returns (uint256)
    {
        return _validateSubstandard4(context, zoneParameters);
    }

    function exposed_validateSubstandard6(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
        returns (uint256)
    {
        return _validateSubstandard6(context, zoneParameters);
    }

    function exposed_deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems,
        uint256 scalingFactorNumerator,
        uint256 scalingFactorDenominator
    ) external pure returns (bytes32) {
        return _deriveReceivedItemsHash(receivedItems, scalingFactorNumerator, scalingFactorDenominator);
    }

    function exposed_bytes32ArrayIncludes(bytes32[] calldata sourceArray, bytes32[] memory values)
        external
        pure
        returns (bool)
    {
        return _bytes32ArrayIncludes(sourceArray, values);
    }

    function exposed_domainSeparator() external view returns (bytes32) {
        return _domainSeparator();
    }

    function exposed_deriveDomainSeparator() external view returns (bytes32 domainSeparator) {
        return _deriveDomainSeparator();
    }
}

// solhint-enable func-name-mixedcase
