// Copyright Immutable Pty Ltd 2018 - 2026
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <=0.8.27;

import {StakeHolderInitBaseTestV2} from "./StakeHolderInitBaseV2.t.sol";

contract StakeHolderInitWIMXTestV2 is StakeHolderInitBaseTestV2 {
    function setUp() public override {
        super.setUp();
        deployWIMX();
        deployStakeHolderWIMXV1();
        upgradeToStakeHolderWIMXV2();
    }
}
