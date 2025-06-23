// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";


abstract contract StakeHolderConfigBaseTestV2 is StakeHolderConfigBaseTest {
    function testUpgradeToV2() override public {
        IStakeHolder v2Impl = _deployV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 2));
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v2Impl), initData);
    }

    function testUpgradeToV1() override public {
        IStakeHolder v1Impl = _deployV1();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 2));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v1Impl), initData);
    }

    function testDowngradeV2ToV1() override public {
        // This test doesn't make sense in the context of V2.
    }

    function testUpgradeToV3() public {
        IStakeHolder v3Impl = _deployV3();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v3Impl), initData);

        assertEq(stakeHolder.version(), 3, "Wrong version");
    }

    function testDowngradeV3ToV2() public {
        // Upgrade from V2 to V3
        IStakeHolder v3Impl = _deployV3();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v3Impl), initData);

        // Attempt to downgrade from V3 to V2.
        IStakeHolder v2Impl = _deployV2();
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 3));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v2Impl), initData);
    }

    function _deployV3() internal virtual returns(IStakeHolder);
}
