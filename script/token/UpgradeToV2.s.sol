// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Script.sol";
import {ImmutableERC721MintByIDUpgradeableV3} from
    "../../contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";
import {ImmutableERC721MintByIDBootstrapV3} from
    "../../contracts/token/erc721/preset/ImmutableERC721MintByIDBootstrapV3.sol";

contract UpgradeToV3 is Script {
    function run() public {
        address proxyDeployedAddress = 0x242BcF5240E6804FA62D68aDeF2459FF1C1b7Bc6;
        address v3Address = 0x6F00F52c2A27caD780FA945aAc56AE9792A061CA;

        ImmutableERC721MintByIDBootstrapV3 bootstrap = ImmutableERC721MintByIDBootstrapV3(proxyDeployedAddress);
        bytes memory initData =
            abi.encodeWithSelector(ImmutableERC721MintByIDUpgradeableV3.upgradeStorage.selector, bytes(""));

        vm.broadcast();
        bootstrap.upgradeToAndCall(v3Address, initData);

        ImmutableERC721MintByIDUpgradeableV3 erc721 = ImmutableERC721MintByIDUpgradeableV3(proxyDeployedAddress);
        require(erc721.version() == 3, "Unexpected version");

        console.logString("Done");
    }
}
