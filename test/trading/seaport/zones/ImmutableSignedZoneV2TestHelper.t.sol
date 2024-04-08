// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {ImmutableSignedZoneV2} from "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ImmutableSignedZoneV2TestHelper is Test {
    // solhint-disable private-vars-leading-underscore
    address internal immutable OWNER = makeAddr("owner"); // 0x7c8999dC9a822c1f0Df42023113EDB4FDd543266
    address internal immutable FULFILLER = makeAddr("fulfiller"); // 0x71458637cD221877830A21F543E8b731e93C3627
    address internal immutable OFFERER = makeAddr("offerer"); // 0xD4A3ED913c988269BbB6caeCBEC568063B43435a
    address internal immutable SIGNER = makeAddr("signer"); // 0x6E12D8C87503D4287c294f2Fdef96ACd9DFf6bd2
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
        bytes32 signatureDigest = ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash);
        (, bytes32 r, bytes32 s) = vm.sign(signerPK, signatureDigest);
        bytes memory extraData = abi.encodePacked(hex"00", FULFILLER, expiration, r, s, context);
        return extraData;
    }

}
