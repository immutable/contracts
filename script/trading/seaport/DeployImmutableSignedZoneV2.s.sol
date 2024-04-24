// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

import {Script} from "forge-std/Script.sol";
import {ImmutableSignedZoneV2} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/ImmutableSignedZoneV2.sol";

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.20;

contract DeployImmutableSignedZoneV2 is Script {
    function run() external {
        vm.startBroadcast();

        new ImmutableSignedZoneV2("ImmutableSignedZone", "", "", address(0xC2E90a3cff62e7F0e659211b1666b658e5042227));

        vm.stopBroadcast();
    }
}
