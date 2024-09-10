// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RegistrationV4} from "../../../../contracts/bridge/x/v4/RegistrationV4.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRegistrationV4Sandbox is Script {
    address public SANDBOX_CONTRACT = 0x2d5C349fD8464DA06a3f90b4B0E9195F3d1b7F98;
    uint256 private SEPOLIA_CHAIN_ID = 11155111;

    RegistrationV4 public registration;

    function run() external returns (RegistrationV4) {
        require(block.chainid == SEPOLIA_CHAIN_ID, "wrong chain id, please use sepolia chain");

        vm.startBroadcast();
        registration = new RegistrationV4(payable(SANDBOX_CONTRACT));
        vm.stopBroadcast();
        return registration;
    }
}
