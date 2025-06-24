// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderInitBaseTestV2} from "./StakeHolderInitBaseV2.t.sol";

contract StakeHolderInitERC20TestV2 is StakeHolderInitBaseTestV2 {

    function setUp() public override {
        super.setUp();
        deployStakeHolderERC20V1();
        upgradeToStakeHolderERC20V2();
    }
}
