// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ReceivedItem, ZoneParameters} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {ImmutableSignedZoneV3} from
    "../../../../../../contracts/trading/seaport16/zones/immutable-signed-zone/v3/ImmutableSignedZoneV3.sol";

// solhint-disable func-name-mixedcase

contract ImmutableSignedZoneV3Harness is ImmutableSignedZoneV3 {
    constructor(string memory zoneName, string memory apiEndpoint, string memory documentationURI, address owner)
        ImmutableSignedZoneV3(zoneName, apiEndpoint, documentationURI, owner)
    {}

    function exposed_domainSeparator() external view returns (bytes32) {
        return _domainSeparator();
    }

    function exposed_deriveDomainSeparator() external view returns (bytes32 domainSeparator) {
        return _deriveDomainSeparator();
    }

    function exposed_getSupportedSubstandards() external pure returns (uint256[] memory substandards) {
        return _getSupportedSubstandards();
    }

    function exposed_deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) external pure returns (bytes32 signedOrderHash) {
        return _deriveSignedOrderHash(fulfiller, expiration, orderHash, context);
    }

    function exposed_validateSubstandards(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
    {
        return _validateSubstandards(context, zoneParameters);
    }

    function exposed_validateSubstandard1(bytes calldata context, ZoneParameters calldata zoneParameters)
        external
        pure
        returns (uint256)
    {
        return _validateSubstandard1(context, zoneParameters);
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
}

// solhint-enable func-name-mixedcase
