// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {StakeHolderOperationalBaseTestV2} from "./StakeHolderOperationalBaseV2.t.sol";
import {StakeHolderOperationalNativeTest} from "./StakeHolderOperationalNative.t.sol";

contract StakeHolderOperationalNativeTestV2 is StakeHolderOperationalNativeTest, StakeHolderOperationalBaseTestV2 {
    function setUp() public override (StakeHolderOperationalNativeTest, StakeHolderBaseTest) {
        StakeHolderOperationalNativeTest.setUp();
        upgradeToStakeHolderNativeV2();
    }
}
