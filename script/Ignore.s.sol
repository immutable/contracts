// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract IgnoreScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}