// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ImmutableSignedZoneV2} from "../../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";

abstract contract ImmutableSignedZoneV2TestHelper is Test {
    address internal OWNER = makeAddr("owner");

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
}
