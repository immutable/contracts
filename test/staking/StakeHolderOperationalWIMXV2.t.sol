// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {StakeHolderOperationalBaseTestV2} from "./StakeHolderOperationalBaseV2.t.sol";
import {StakeHolderOperationalWIMXTest} from "./StakeHolderOperationalWIMX.t.sol";

contract StakeHolderOperationalWIMXTestV2 is StakeHolderOperationalWIMXTest, StakeHolderOperationalBaseTestV2 {
    function setUp() public override (StakeHolderOperationalWIMXTest, StakeHolderBaseTest) {
        StakeHolderOperationalWIMXTest.setUp();
        upgradeToStakeHolderWIMXV2();
    }
}
