// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {ImmutableSignedZoneV2} from "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SigningTestHelper} from "../utils/SigningTestHelper.t.sol";

abstract contract ImmutableSignedZoneV2TestHelper is Test, SigningTestHelper {
    // solhint-disable private-vars-leading-underscore
    address internal immutable OWNER = makeAddr("owner");
    address internal immutable FULFILLER = makeAddr("fulfiller");
    address internal immutable OFFERER = makeAddr("offerer");
    address internal immutable SIGNER = makeAddr("signer");
    // solhint-enable private-vars-leading-underscore

    function _newZone() internal returns (ImmutableSignedZoneV2) {
        return new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            OWNER
        );
    }

    function _newZoneHarness() internal returns (ImmutableSignedZoneV2Harness) {
        return new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            OWNER
        );
    }

    function _buildExtraData(
        ImmutableSignedZoneV2Harness zone,
        bytes32 orderHash,
        uint64 expiration,
        bytes memory context
    ) internal returns (bytes memory) {
        (, uint256 signerPK) = makeAddrAndKey("signer");
        bytes32 eip712SignedOrderHash = zone.exposed_deriveSignedOrderHash(FULFILLER, expiration, orderHash, context);
        bytes memory extraData = abi.encodePacked(
            bytes1(0),
            FULFILLER,
            expiration,
            _signCompact(signerPK, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)),
            context
        );
        return extraData;
    }
}
