// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

import {Script} from "forge-std/Script.sol";
import {ImmutableSignedZoneV2} from
    "../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/ImmutableSignedZoneV2.sol";

// solhint-disable-next-line compiler-version
pragma solidity 0.8.24;

// Deploy ImmutableSignedZoneV2 to dev environment (without create3)
contract DeployImmutableSignedZoneV2Dev is Script {
    function run() external {
        vm.startBroadcast();

        // replace args with test values if necessary
        ImmutableSignedZoneV2 c = new ImmutableSignedZoneV2(
            "ImmutableSignedZone", "", "", address(0xC606830D8341bc9F5F5Dd7615E9313d2655B505D)
        );

        c.grantRole(bytes32("ZONE_MANAGER"), address(0xC606830D8341bc9F5F5Dd7615E9313d2655B505D));

        // set server side signer address
        c.addSigner(address(0xBE63B9F9F2Ed97fac4b71630268bC050ddB53395));

        vm.stopBroadcast();
    }
}

// forge script script/trading/seaport/DeployImmutableSignedZoneV2Dev.s.sol:DeployImmutableSignedZoneV2Dev --rpc-url "https://rpc.dev.immutable.com" --broadcast -vvvv --priority-gas-price 10000000000 --with-gas-price 11000000000 --private-key=xx
