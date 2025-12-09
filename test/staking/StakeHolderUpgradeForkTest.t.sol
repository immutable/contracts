// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import {Test} from "forge-std/Test.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";

contract StakeHolderUpgradeForkTest is Test {
    string constant MAINNET_RPC_URL = "https://rpc.immutable.com/";
    address constant STAKE_HOLDER_PROXY = 0xb6c2aA8690C8Ab6AC380a0bb798Ab0debe5C4C38;
    address constant TIMELOCK_CONTROLLER = 0x994a66607f947A47F33C2fA80e0470C03C30e289;
    address constant WIMX = 0x3A0C2Ba54D6CBd3121F01b96dFd20e99D1696C9D;

    bytes32 constant PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;
    bytes32 constant EXECUTOR_ROLE = 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63;

    address constant PROPOSER = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;
    address constant EXECUTOR = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;

    uint256 constant TIMELOCK_DELAY = 604800;

    uint256 constant STAKERS_TO_CHECK = 100;

    StakeHolderWIMX stakeHolder;
    TimelockController stakeHolderTimeDelay;

    // Put the variables below into storage so we don't need to worry about 
    // stack depth issues.
    address stakingTokenAddress;
    uint256 numStakers;
    address[] stakers;
    uint256[] stakersBalances;
    address stakingTokenAddress2;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        stakeHolder = StakeHolderWIMX(payable(STAKE_HOLDER_PROXY));
        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));
    }

    function testUpgradeToV2() public {
        if (stakeHolder.version() != 0) {
            // Don't run the rest of this test after the upgrade happens.
            // It would fail if we were to run the test.
            return;
        }
        //console.log("Executing Staking Contract Upgrade Fork Test");

        stakingTokenAddress = stakeHolder.getToken();
        assertEq(WIMX, stakingTokenAddress, "WIMX address incorrect prior to upgrade");

        numStakers = stakeHolder.getNumStakers();
        assertGe(numStakers, 822, "Wrong number of stakers");
        {
            address[] memory stakersMem = stakeHolder.getStakers(0, STAKERS_TO_CHECK);
            for (uint256 i = 0; i < STAKERS_TO_CHECK; i++) {
                stakers.push(stakersMem[i]);
            }
        }
        for (uint256 i = 0; i < stakers.length; i++) {
            stakersBalances.push(stakeHolder.getBalance(stakers[i]));
        }

        uint256 delay = stakeHolderTimeDelay.getMinDelay();
        assertEq(delay, TIMELOCK_DELAY, "Unexpected timelock delay");
        assertTrue(stakeHolderTimeDelay.hasRole(PROPOSER_ROLE, PROPOSER), "Proposer does not have proposer role");
        assertTrue(stakeHolderTimeDelay.hasRole(EXECUTOR_ROLE, EXECUTOR), "Executor does not have executor role");

        StakeHolderWIMXV2 v2Impl = new StakeHolderWIMXV2();

        bytes memory callData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        bytes memory upgradeCall = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeToAndCall.selector, address(v2Impl), callData);

        address target = address(stakeHolder);
        uint256 value = 0;
        bytes memory data = upgradeCall;
        bytes32 predecessor = bytes32(0);
        bytes32 salt = bytes32(uint256(1));
        uint256 theDelay = delay;

        uint256 timeNow = block.timestamp;

        vm.prank(PROPOSER);
        stakeHolderTimeDelay.schedule(
            target, value, data, predecessor, salt, theDelay);

        vm.warp(timeNow + delay);

        vm.prank(EXECUTOR);
        stakeHolderTimeDelay.execute(target, value, data, predecessor, salt);

        assertEq(stakeHolder.version(), 2, "Upgrade did not upgrade version 2");

        stakingTokenAddress2 = stakeHolder.getToken();
        assertEq(stakingTokenAddress, stakingTokenAddress2, "Staking token address incorrect after upgrade");

        uint256 numStakers2 = stakeHolder.getNumStakers();
        assertGe(numStakers2, numStakers, "After upgrade: Wrong number of stakers");
        address[] memory stakers2 = stakeHolder.getStakers(0, stakers.length);

        for (uint256 i = 0; i < stakers.length; i++) {
            assertEq(stakers[i], stakers2[i], "Stakers arrays don't match");
        }
        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 bal = stakeHolder.getBalance(stakers[i]);
            assertEq(bal, stakersBalances[i], "Balance changed");
        }
    }
}
