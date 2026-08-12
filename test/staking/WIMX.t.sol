// Copyright Immutable Pty Ltd 2018 - 2026
// SPDX-License-Identifier: Apache 2.0

pragma solidity >=0.8.19 <=0.8.27;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import {IWIMX} from "../../contracts/staking/IWIMX.sol";
import {WIMX} from "../../contracts/staking/WIMX.sol";

contract WIMXTest is Test {
    WIMX private wimx;

    address private alice;
    address private bob;
    address private carol;

    function setUp() public {
        wimx = new WIMX();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
    }

    function test_metadata() public view {
        assertEq(wimx.name(), "Wrapped IMX");
        assertEq(wimx.symbol(), "WIMX");
        assertEq(wimx.decimals(), 18);
    }

    function test_deposit_increasesBalanceAndEmitsEvent() public {
        vm.deal(alice, 10 ether);

        vm.expectEmit(true, false, false, true);
        emit IWIMX.Deposit(alice, 4 ether);

        vm.prank(alice);
        wimx.deposit{value: 4 ether}();

        assertEq(wimx.balanceOf(alice), 4 ether);
        assertEq(address(wimx).balance, 4 ether);
    }

    function test_receive_depositsViaPlainNativeTransfer() public {
        vm.deal(alice, 10 ether);

        vm.expectEmit(true, false, false, true);
        emit IWIMX.Deposit(alice, 3 ether);

        vm.prank(alice);
        (bool success,) = address(wimx).call{value: 3 ether}("");

        assertTrue(success);
        assertEq(wimx.balanceOf(alice), 3 ether);
        assertEq(address(wimx).balance, 3 ether);
    }

    function test_deposit_zeroValueIsANoOpButStillEmits() public {
        vm.expectEmit(true, false, false, true);
        emit IWIMX.Deposit(alice, 0);

        vm.prank(alice);
        wimx.deposit();

        assertEq(wimx.balanceOf(alice), 0);
    }

    function test_totalSupply_reflectsContractNativeBalance() public {
        assertEq(wimx.totalSupply(), 0);

        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        assertEq(wimx.totalSupply(), 5 ether);
        assertEq(wimx.totalSupply(), address(wimx).balance);
    }

    function test_withdraw_decreasesBalanceAndSendsNative() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        vm.expectEmit(true, false, false, true);
        emit IWIMX.Withdrawal(alice, 2 ether);

        vm.prank(alice);
        wimx.withdraw(2 ether);

        assertEq(wimx.balanceOf(alice), 3 ether);
        assertEq(alice.balance, 2 ether);
        assertEq(address(wimx).balance, 3 ether);
    }

    function test_withdraw_fullBalance() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        wimx.deposit{value: 1 ether}();

        vm.prank(alice);
        wimx.withdraw(1 ether);

        assertEq(wimx.balanceOf(alice), 0);
        assertEq(alice.balance, 1 ether);
        assertEq(wimx.totalSupply(), 0);
    }

    function test_withdraw_revertsIfInsufficientBalance() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        wimx.deposit{value: 1 ether}();

        vm.expectRevert("Wrapped IMX: Insufficient balance");
        vm.prank(alice);
        wimx.withdraw(2 ether);
    }

    function test_withdraw_revertsIfNoBalance() public {
        vm.expectRevert("Wrapped IMX: Insufficient balance");
        vm.prank(alice);
        wimx.withdraw(1);
    }

    function test_approve_setsAllowanceAndEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(alice, bob, 7 ether);

        vm.prank(alice);
        bool success = wimx.approve(bob, 7 ether);

        assertTrue(success);
        assertEq(wimx.allowance(alice, bob), 7 ether);
    }

    function test_approve_overwritesPreviousAllowance() public {
        vm.startPrank(alice);
        wimx.approve(bob, 7 ether);
        wimx.approve(bob, 1 ether);
        vm.stopPrank();

        assertEq(wimx.allowance(alice, bob), 1 ether);
    }

    function test_transfer_movesBalanceAndEmitsEvent() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(alice, bob, 2 ether);

        vm.prank(alice);
        bool success = wimx.transfer(bob, 2 ether);

        assertTrue(success);
        assertEq(wimx.balanceOf(alice), 3 ether);
        assertEq(wimx.balanceOf(bob), 2 ether);
    }

    function test_transfer_revertsIfInsufficientBalance() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        wimx.deposit{value: 1 ether}();

        vm.expectRevert("Wrapped IMX: Insufficient balance");
        vm.prank(alice);
        wimx.transfer(bob, 2 ether);
    }

    function test_transferFrom_bySourceItself_doesNotRequireAllowance() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        // alice calling transferFrom(alice, bob, ...) directly, with zero allowance set,
        // must succeed because src == msg.sender bypasses the allowance check.
        assertEq(wimx.allowance(alice, alice), 0);

        vm.prank(alice);
        bool success = wimx.transferFrom(alice, bob, 2 ether);

        assertTrue(success);
        assertEq(wimx.balanceOf(alice), 3 ether);
        assertEq(wimx.balanceOf(bob), 2 ether);
    }

    function test_transferFrom_withExplicitAllowance_decrementsAllowance() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        vm.prank(alice);
        wimx.approve(bob, 3 ether);

        vm.prank(bob);
        bool success = wimx.transferFrom(alice, carol, 2 ether);

        assertTrue(success);
        assertEq(wimx.balanceOf(alice), 3 ether);
        assertEq(wimx.balanceOf(carol), 2 ether);
        assertEq(wimx.allowance(alice, bob), 1 ether);
    }

    function test_transferFrom_withInfiniteAllowance_doesNotDecrementAllowance() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        vm.prank(alice);
        wimx.approve(bob, type(uint256).max);

        vm.prank(bob);
        wimx.transferFrom(alice, carol, 2 ether);

        assertEq(wimx.allowance(alice, bob), type(uint256).max);
    }

    function test_transferFrom_revertsIfInsufficientAllowance() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        wimx.deposit{value: 5 ether}();

        vm.prank(alice);
        wimx.approve(bob, 1 ether);

        vm.expectRevert("Wrapped IMX: Insufficient allowance");
        vm.prank(bob);
        wimx.transferFrom(alice, carol, 2 ether);
    }

    function test_transferFrom_revertsIfInsufficientBalance() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        wimx.deposit{value: 1 ether}();

        vm.prank(alice);
        wimx.approve(bob, 10 ether);

        vm.expectRevert("Wrapped IMX: Insufficient balance");
        vm.prank(bob);
        wimx.transferFrom(alice, carol, 2 ether);
    }

    function testFuzz_depositThenWithdraw_roundTrips(uint96 amount) public {
        vm.deal(alice, uint256(amount));

        vm.prank(alice);
        wimx.deposit{value: amount}();
        assertEq(wimx.balanceOf(alice), amount);

        vm.prank(alice);
        wimx.withdraw(amount);

        assertEq(wimx.balanceOf(alice), 0);
        assertEq(alice.balance, amount);
        assertEq(address(wimx).balance, 0);
    }
}
