// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderInitBaseTest} from "./StakeHolderInitBase.t.sol";

contract StakeHolderInitNativeTest is StakeHolderInitBaseTest {

    function setUp() public override {
        super.setUp();
        deployStakeHolderNativeV1();
    }
}
