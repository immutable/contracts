// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {StakeHolderOperationalBaseTestV2} from "./StakeHolderOperationalBaseV2.t.sol";
import {StakeHolderOperationalERC20Test} from "./StakeHolderOperationalERC20.t.sol";

contract StakeHolderOperationalERC20TestV2 is StakeHolderOperationalERC20Test, StakeHolderOperationalBaseTestV2 {
    function setUp() public override (StakeHolderOperationalERC20Test, StakeHolderBaseTest) {
        StakeHolderOperationalERC20Test.setUp();
        upgradeToStakeHolderERC20V2();
    }
}
