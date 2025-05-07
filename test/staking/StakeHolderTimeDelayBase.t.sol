// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";


abstract contract StakeHolderTimeDelayBaseTest is StakeHolderBaseTest {
    TimelockController stakeHolderTimeDelay;

    uint256 delay = 604800; // 604800 seconds = 1 week

    address adminProposer;
    address adminExecutor;

    function setUp() public virtual override {
        super.setUp();

        adminProposer = makeAddr("adminProposer");
        adminExecutor = makeAddr("adminExecutor");

        address[] memory proposers = new address[](1);
        proposers[0] = adminProposer;
        address[] memory executors = new address[](1);
        executors[0] = adminExecutor;

        stakeHolderTimeDelay = new TimelockController(delay, proposers, executors, address(0));
    }


    function testTimeLockControllerDeployment() public {
        assertEq(stakeHolderTimeDelay.getMinDelay(), delay, "Incorrect time delay");
    }

    function testUpgrade() public {
        IStakeHolder v2Impl = _deployV2();

        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        bytes memory upgradeCall = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeToAndCall.selector, address(v2Impl), initData);

        address target = address(stakeHolder);
        uint256 value = 0;
        bytes memory data = upgradeCall;
        bytes32 predecessor = bytes32(0);
        bytes32 salt = bytes32(uint256(1));
        uint256 theDelay = delay;

        uint256 timeNow = block.timestamp;

        vm.prank(adminProposer);
        stakeHolderTimeDelay.schedule(
            target, value, data, predecessor, salt, theDelay);

        vm.warp(timeNow + delay);

        vm.prank(adminExecutor);
        stakeHolderTimeDelay.execute(target, value, data, predecessor, salt);

        uint256 ver = stakeHolder.version();
        assertEq(ver, 1, "Upgrade did not upgrade version");
    }

    function testTooShortDelay() public {
        IStakeHolder v2Impl = _deployV2();

        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        bytes memory upgradeCall = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeToAndCall.selector, address(v2Impl), initData);

        address target = address(stakeHolder);
        uint256 value = 0;
        bytes memory data = upgradeCall;
        bytes32 predecessor = bytes32(0);
        bytes32 salt = bytes32(uint256(1));
        uint256 theDelay = delay - 1; // Too small

        vm.expectRevert(abi.encodePacked("TimelockController: insufficient delay"));
        vm.prank(adminProposer);
        stakeHolderTimeDelay.schedule(
            target, value, data, predecessor, salt, theDelay);
    }

    function testExecuteEarly() public {
        IStakeHolder v2Impl = _deployV2();

        bytes memory initData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        bytes memory upgradeCall = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeToAndCall.selector, address(v2Impl), initData);

        address target = address(stakeHolder);
        uint256 value = 0;
        bytes memory data = upgradeCall;
        bytes32 predecessor = bytes32(0);
        bytes32 salt = bytes32(uint256(1));
        uint256 theDelay = delay;

        uint256 timeNow = block.timestamp;

        vm.prank(adminProposer);
        stakeHolderTimeDelay.schedule(
            target, value, data, predecessor, salt, theDelay);

        vm.expectRevert(abi.encodePacked("TimelockController: operation is not ready"));
        vm.warp(timeNow + delay - 1); // Too early

        vm.prank(adminExecutor);
        stakeHolderTimeDelay.execute(target, value, data, predecessor, salt);
    }




    function _deployV2() internal virtual returns(IStakeHolder);
}
