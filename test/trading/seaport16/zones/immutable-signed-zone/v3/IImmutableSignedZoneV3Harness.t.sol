// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ZoneInterface} from "seaport-16/contracts/interfaces/ZoneInterface.sol";
import {ReceivedItem, ZoneParameters} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {SIP7Interface} from "../../../../../../contracts/trading/seaport16/zones/immutable-signed-zone/v3/interfaces/SIP7Interface.sol";

// solhint-disable func-name-mixedcase

interface IImmutableSignedZoneV3Harness is ZoneInterface, SIP7Interface {
    function grantRole(bytes32 role, address account) external;

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function ZONE_MANAGER_ROLE() external view returns (bytes32);

    function exposed_domainSeparator() external view returns (bytes32);

    function exposed_deriveDomainSeparator() external view returns (bytes32 domainSeparator);

    function exposed_getSupportedSubstandards() external pure returns (uint256[] memory substandards);

    function exposed_deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) external view returns (bytes32 signedOrderHash);

    function exposed_validateSubstandards(bytes calldata context, ZoneParameters calldata zoneParameters, bool before)
        external;

    function exposed_validateSubstandard3(bytes calldata context, ZoneParameters calldata zoneParameters, bool before)
        external
        pure
        returns (uint256);

    function exposed_validateSubstandard4(bytes calldata context, ZoneParameters calldata zoneParameters, bool before)
        external
        pure
        returns (uint256);

    function exposed_validateSubstandard6(bytes calldata context, ZoneParameters calldata zoneParameters, bool before)
        external
        pure
        returns (uint256);

    function exposed_validateSubstandard7(bytes calldata context, ZoneParameters calldata zoneParameters, bool before)
        external
        returns (uint256);

    function exposed_deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems,
        uint256 scalingFactorNumerator,
        uint256 scalingFactorDenominator
    ) external pure returns (bytes32);

    function exposed_bytes32ArrayIncludes(bytes32[] calldata sourceArray, bytes32[] memory values)
        external
        pure
        returns (bool);
}

// solhint-enable func-name-mixedcase
