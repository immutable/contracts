// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RegistrationV4} from "../../../../contracts/bridge/x/v4/RegistrationV4.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRegistrationV4 is Script {
    address public MAINNET_CONTRACT = 0x5FDCCA53617f4d2b9134B29090C87D01058e27e9;
    uint256 private MAINNET_CHAIN_ID = 1;

    RegistrationV4 public registration;

    function run() external returns (RegistrationV4) {
        require(block.chainid == MAINNET_CHAIN_ID, "wrong chain id, please use mainnet chain");

        vm.startBroadcast();
        registration = new RegistrationV4(payable(MAINNET_CONTRACT));
        vm.stopBroadcast();
        return registration;
    }
}
