// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {StakeHolderInitBaseTestV2} from "./StakeHolderInitBaseV2.t.sol";

contract StakeHolderInitNativeTestV2 is StakeHolderInitBaseTestV2 {

    function setUp() public override {
        super.setUp();
        deployStakeHolderNativeV1();
        upgradeToStakeHolderNativeV2();
    }
}
