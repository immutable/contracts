// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";


abstract contract StakeHolderConfigBaseTest is StakeHolderBaseTest {
    function testUpgradeToV2() public virtual {
        IStakeHolder v2Impl = _deployV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v2Impl), initData);

        uint256 ver = stakeHolder.version();
        assertEq(ver, 2, "Upgrade did not upgrade version");
    }

    function testUpgradeToV1() public virtual {
        IStakeHolder v1Impl = _deployV1();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 0));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v1Impl), initData);
    }

    function testDowngradeV2ToV1() public virtual {
        // Upgrade from V0 to V2
        IStakeHolder v2Impl = _deployV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v2Impl), initData);

        // Attempt to downgrade from V1 to V0.
        IStakeHolder v1Impl = _deployV1();
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 2));
        vm.prank(upgradeAdmin);
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v1Impl), initData);
    }

    function testUpgradeAuthFail() public {
        IStakeHolder v2Impl = _deployV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        // Error will be of the form: 
        // AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x555047524144455f524f4c450000000000000000000000000000000000000000
        vm.expectRevert();
        StakeHolderBase(address(stakeHolder)).upgradeToAndCall(address(v2Impl), initData);
    }

    function testAddRevokeRenounceRoleAdmin() public {
        bytes32 role = defaultAdminRole;
        address newRoleAdmin = makeAddr("NewRoleAdmin");
        vm.prank(roleAdmin);
        stakeHolder.grantRole(role, newRoleAdmin);

        vm.startPrank(newRoleAdmin);
        stakeHolder.revokeRole(role, roleAdmin);
        stakeHolder.grantRole(role, roleAdmin);
        stakeHolder.renounceRole(role, newRoleAdmin);
        vm.stopPrank();
    }

    function testAddRevokeRenounceUpgradeAdmin() public {
        bytes32 role = stakeHolder.UPGRADE_ROLE();
        address newUpgradeAdmin = makeAddr("NewUpgradeAdmin");
        vm.startPrank(roleAdmin);
        stakeHolder.grantRole(role, newUpgradeAdmin);
        assertTrue(stakeHolder.hasRole(role, newUpgradeAdmin), "New upgrade admin should have role");
        stakeHolder.revokeRole(role, newUpgradeAdmin);
        assertFalse(stakeHolder.hasRole(role, newUpgradeAdmin), "New upgrade admin should not have role");
        vm.stopPrank();
        vm.prank(upgradeAdmin);
        stakeHolder.renounceRole(role, upgradeAdmin);
        assertFalse(stakeHolder.hasRole(role, upgradeAdmin), "Upgrade admin should not have role");
    }

    function testRoleAdminAuthFail () public {
        bytes32 role = defaultAdminRole;
        address newRoleAdmin = makeAddr("NewRoleAdmin");
        // Error will be of the form: 
        // AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x555047524144455f524f4c450000000000000000000000000000000000000000
        vm.expectRevert();
        stakeHolder.grantRole(role, newRoleAdmin);
    }


    function _deployV1() internal virtual returns(IStakeHolder);
    function _deployV2() internal virtual returns(IStakeHolder);
}
