// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolder} from "../../contracts/staking/StakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";

contract StakeHolderV2 is StakeHolder {
    function upgradeStorage(bytes memory /* _data */ ) external override {
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
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 0));
        vm.prank(upgradeAdmin);
        stakeHolder.upgradeToAndCall(address(v1Impl), initData);
    }

    function testDowngradeV1ToV0() public {
        // Upgrade from V0 to V1
        StakeHolderV2 v2Impl = new StakeHolderV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolder.upgradeStorage.selector, bytes(""));
        vm.prank(upgradeAdmin);
        stakeHolder.upgradeToAndCall(address(v2Impl), initData);

        // Attempt to downgrade from V1 to V0.
        StakeHolder v1Impl = new StakeHolder();
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.CanNotUpgradeToLowerOrSameVersion.selector, 1));
        vm.prank(upgradeAdmin);
        stakeHolder.upgradeToAndCall(address(v1Impl), initData);
    }

    function testUpgradeAuthFail() public {
        StakeHolderV2 v2Impl = new StakeHolderV2();
        bytes memory initData = abi.encodeWithSelector(StakeHolder.upgradeStorage.selector, bytes(""));
        // Error will be of the form:
        // AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x555047524144455f524f4c450000000000000000000000000000000000000000
        vm.expectRevert();
        stakeHolder.upgradeToAndCall(address(v2Impl), initData);
    }

    function testAddRevokeRenounceRoleAdmin() public {
        bytes32 role = stakeHolder.DEFAULT_ADMIN_ROLE();
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

    function testRenounceLastRoleAdmin() public {
        bytes32 role = stakeHolder.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.MustHaveOneRoleAdmin.selector));
        vm.prank(roleAdmin);
        stakeHolder.renounceRole(role, roleAdmin);
    }

    function testRevokeLastRoleAdmin() public {
        bytes32 role = stakeHolder.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.MustHaveOneRoleAdmin.selector));
        vm.prank(roleAdmin);
        stakeHolder.revokeRole(role, roleAdmin);
    }

    function testRoleAdminAuthFail() public {
        bytes32 role = stakeHolder.DEFAULT_ADMIN_ROLE();
        address newRoleAdmin = makeAddr("NewRoleAdmin");
        // Error will be of the form:
        // AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x555047524144455f524f4c450000000000000000000000000000000000000000
        vm.expectRevert();
        stakeHolder.grantRole(role, newRoleAdmin);
    }
}
