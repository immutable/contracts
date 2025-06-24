// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderInitBaseTest} from "./StakeHolderInitBase.t.sol";

abstract contract StakeHolderInitBaseTestV2 is StakeHolderInitBaseTest {
    function testGetVersion() public override {
        uint256 ver = stakeHolder.version();
        assertEq(ver, 2, "Incorrect version");
    }
}
