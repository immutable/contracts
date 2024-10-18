// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolder, AccountAmount} from "../../contracts/staking/StakeHolder.sol";
import {StakeHolderAttackWallet} from "./StakeHolderAttackWallet.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";

contract StakeHolderOperationalTest is StakeHolderBaseTest {
    function testStake() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
        address[] memory stakers = stakeHolder.getStakers(0, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker");
    }

    function testStakeTwice() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker1);
        stakeHolder.stake{value: 20 ether}();

        assertEq(stakeHolder.getBalance(staker1), 30 ether, "Incorrect balance");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
    }

    function testStakeZeroValue() public {
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.MustStakeMoreThanZero.selector));
        vm.prank(staker1);
        stakeHolder.stake();
    }

    function testMultipleStakers() public {
        vm.deal(staker1, 100 ether);
        vm.deal(staker2, 100 ether);
        vm.deal(staker3, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker2);
        stakeHolder.stake{value: 20 ether}();
        vm.prank(staker3);
        stakeHolder.stake{value: 30 ether}();

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked1");
        assertEq(stakeHolder.getBalance(staker2), 20 ether, "Incorrect balance2");
        assertTrue(stakeHolder.hasStaked(staker2), "Expect staker1 has staked2");
        assertEq(stakeHolder.getBalance(staker3), 30 ether, "Incorrect balance3");
        assertTrue(stakeHolder.hasStaked(staker3), "Expect staker1 has staked3");

        assertEq(stakeHolder.getNumStakers(), 3, "Incorrect number of stakers");
        address[] memory stakers = stakeHolder.getStakers(0, 3);
        assertEq(stakers.length, 3, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker1");
        assertEq(stakers[1], staker2, "Incorrect staker2");
        assertEq(stakers[2], staker3, "Incorrect staker3");
    }

    function testUnstake() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker1);
        stakeHolder.unstake(10 ether);

        assertEq(staker1.balance, 100 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 0 ether, "Incorrect balance");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
        address[] memory stakers = stakeHolder.getStakers(0, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker");
    }

    function testUnstakeTooMuch() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.expectRevert(abi.encodeWithSelector(StakeHolder.UnstakeAmountExceedsBalance.selector, 11 ether, 10 ether));
        vm.prank(staker1);
        stakeHolder.unstake(11 ether);
    }

    function testUnstakePartial() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker1);
        stakeHolder.unstake(3 ether);

        assertEq(staker1.balance, 93 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 7 ether, "Incorrect balance");
    }

    function testUnstakeMultiple() public {
        vm.deal(staker1, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker1);
        stakeHolder.unstake(3 ether);
        vm.prank(staker1);
        stakeHolder.unstake(1 ether);

        assertEq(staker1.balance, 94 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 6 ether, "Incorrect balance");
    }

    function testUnstakeReentrantAttack() public {
        StakeHolderAttackWallet attacker = new StakeHolderAttackWallet(address(stakeHolder));
        vm.deal(address(attacker), 100 ether);

        attacker.stake(10 ether);
        // Attacker's reentracy attack will double the amount being unstaked.
        // The attack fails due to an out of gas exception.
        vm.expectRevert();
        attacker.unstake{gas: 10000000}(1 ether);
    }

    function testDistributeRewardsOne() public {
        vm.deal(staker1, 100 ether);
        vm.deal(staker2, 100 ether);
        vm.deal(staker3, 100 ether);
        vm.deal(bank, 100 ether);

        vm.prank(staker1);
        stakeHolder.stake{value: 10 ether}();
        vm.prank(staker2);
        stakeHolder.stake{value: 20 ether}();
        vm.prank(staker3);
        stakeHolder.stake{value: 30 ether}();

        // Distribute rewards to staker2 only.
        AccountAmount[] memory accountsAmounts = new AccountAmount[](1);
        accountsAmounts[0] = AccountAmount(staker2, 0.5 ether);
        vm.prank(bank);
        stakeHolder.distributeRewards{value: 0.5 ether}(accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertEq(stakeHolder.getBalance(staker2), 20.5 ether, "Incorrect balance2");
        assertEq(stakeHolder.getBalance(staker3), 30 ether, "Incorrect balance3");
    }

}
