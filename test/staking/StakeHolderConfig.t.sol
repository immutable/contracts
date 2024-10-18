// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolder} from "../../contracts/staking/StakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";

contract StakeHolderV2 is StakeHolder {
    function upgradeStorage(bytes memory /* _data */) external override {
        version = 1;
    }
}

contract StakeHolderConfigTest is StakeHolderBaseTest {
    function testUpgradeToV1() public {
        StakeHolderV2 v2Impl = new StakeHolderV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolder.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        stakeHolder.upgradeToAndCall(address(v2Impl), initData);

        uint256 ver = stakeHolder.version();
        assertEq(ver, 1, "Upgrade did not upgrade version");
    }

    function testUpgradeToV0() public {
        StakeHolder v1Impl = new StakeHolder();
        bytes memory initData = abi.encodeWithSelector(StakeHolder.upgradeStorage.selector, bytes(""));
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.CanNotUpgradeToV0.selector, 0));
        vm.prank(upgradeAdmin);
        stakeHolder.upgradeToAndCall(address(v1Impl), initData);
    }
}
