// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Multicall3} from "../../contracts/multicall/Multicall3.sol";

// Simple ERC20 token for testing
contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Wrapped ETH implementation (simplified)
contract WETH is ERC20 {
    constructor() ERC20("Wrapped ETH", "WETH") {}

    // Deposit ETH to get WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    // Withdraw ETH by burning WETH
    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    // For compatibility with WETH9
    receive() external payable {
        deposit();
    }
}

contract StakeHolderERC20Multicall3Test is Test {
    StakeHolderERC20 public stakeHolderERC20;
    WETH public weth;
    Multicall3 public multicall3;

    // Only need admin for admin roles and staker for staking
    address public admin;
    address public staker;

    function setUp() public {
        // Setup addresses
        admin = makeAddr("admin");
        staker = makeAddr("staker");

        // Deploy wrapped ETH token
        weth = new WETH();

        // Deploy StakeHolderERC20 with WETH as the staking token
        stakeHolderERC20 = new StakeHolderERC20();
        stakeHolderERC20.initialize(
            admin,  // role admin
            admin,  // upgrade admin
            admin,  // distribute admin
            address(weth)
        );

        // Deploy Multicall3 contract
        multicall3 = new Multicall3();

        // Give staker some ETH
        vm.deal(staker, 1000 ether);
    }

    function testConvertAndStakeViaMulticall3() public {
        uint256 stakeAmount = 100 ether;

        // Verify initial conditions
        assertEq(stakeHolderERC20.getBalance(staker), 0);
        assertEq(weth.balanceOf(staker), 0);
        assertEq(address(staker).balance, 1000 ether);

        // Before executing the calls
        console.log("Initial balance::staker", address(staker).balance);
        console.log("Initial balance::multicaller", address(multicall3).balance);
        console.log("Initial WETH balance::staker", weth.balanceOf(staker));
        console.log("Initial WETH balance::multicaller", weth.balanceOf(address(multicall3)));
        console.log("Initial stake balance::staker", stakeHolderERC20.getBalance(staker));
        console.log("Initial stake balance::multicaller", stakeHolderERC20.getBalance(address(multicall3)));

        // Set up the multicall3 calls with value
        Multicall3.Call3Value[] memory callsWithValue = new Multicall3.Call3Value[](3);

        // First call: deposit ETH to get WETH
        callsWithValue[0] = Multicall3.Call3Value({
            target: address(weth),
            allowFailure: false,
            value: stakeAmount,
            callData: abi.encodeWithSignature("deposit()")
        });

        // - Above function is called by multicaller
        // - WIMX is owned by multicaller

        // Approval is necessary because StakeHolderERC20.stake() uses transferFrom
        // to move tokens from the staker to the contract
        callsWithValue[1] = Multicall3.Call3Value({
            target: address(weth),
            allowFailure: false,
            value: 0,
            callData: abi.encodeWithSignature(
                "approve(address,uint256)",
                address(stakeHolderERC20),
                stakeAmount
            )
        });

        // Second regular call: stake WETH tokens
        callsWithValue[2] = Multicall3.Call3Value({
            target: address(stakeHolderERC20),
            allowFailure: false,
            value: 0,
            callData: abi.encodeWithSignature(
                "stake(uint256)",
                stakeAmount
            )
        });

        // Execute the calls as staker
        vm.startPrank(staker);

        // First execute the call that converts ETH to WETH
        multicall3.aggregate3Value{value: stakeAmount}(callsWithValue);

        // Then execute the calls to approve and stake
        // multicall3.aggregate3(calls);

        vm.stopPrank();

        // After execution
        console.log("Final balance::staker", address(staker).balance);
        console.log("Final balance::multicaller", address(multicall3).balance);
        console.log("Final WETH balance::staker", weth.balanceOf(staker));
        console.log("Final WETH balance::multicaller", weth.balanceOf(address(multicall3)));
        console.log("Final stake balance::staker", stakeHolderERC20.getBalance(staker));
        console.log("Final stake balance::multicaller", stakeHolderERC20.getBalance(address(multicall3)));
        console.log("WETH in stake contract:", weth.balanceOf(address(stakeHolderERC20)));

        // Verify the ETH was converted to WETH and then staked
        assertEq(address(staker).balance, 900 ether); // 1000 - 100 ETH
        assertEq(weth.balanceOf(staker), 0); // All WETH should be staked
        assertEq(stakeHolderERC20.getBalance(address(multicall3)), stakeAmount); // 100 WETH staked

        // // Verify WETH balance in the StakeHolder contract
        assertEq(weth.balanceOf(address(stakeHolderERC20)), stakeAmount);
    }

    function testDepositedWIMXIsOwnedByMulticaller() public {
        uint256 stakeAmount = 100 ether;

        // Verify initial conditions
        assertEq(stakeHolderERC20.getBalance(staker), 0);
        assertEq(weth.balanceOf(staker), 0);
        assertEq(address(staker).balance, 1000 ether);

        // Before executing the calls
        console.log("Initial balance::staker", address(staker).balance);
        console.log("Initial balance::multicaller", address(multicall3).balance);
        console.log("Initial WETH balance::staker", weth.balanceOf(staker));
        console.log("Initial WETH balance::multicaller", weth.balanceOf(address(multicall3)));
        console.log("Initial stake balance::staker", stakeHolderERC20.getBalance(staker));
        console.log("Initial stake balance::multicaller", stakeHolderERC20.getBalance(address(multicall3)));

        // Set up the multicall3 calls with value
        Multicall3.Call3Value[] memory callsWithValue = new Multicall3.Call3Value[](1);

        // First call: deposit ETH to get WETH
        callsWithValue[0] = Multicall3.Call3Value({
            target: address(weth),
            allowFailure: false,
            value: stakeAmount,
            callData: abi.encodeWithSignature("deposit()")
        });

        // Execute the calls as staker
        vm.startPrank(staker);

        // First execute the call that converts ETH to WETH
        multicall3.aggregate3Value{value: stakeAmount}(callsWithValue);

        vm.stopPrank();

        // After execution
        console.log("Final balance::staker", address(staker).balance);
        console.log("Final balance::multicaller", address(multicall3).balance);
        console.log("Final WETH balance::staker", weth.balanceOf(staker));
        console.log("Final WETH balance::multicaller", weth.balanceOf(address(multicall3)));
        console.log("Final stake balance::staker", stakeHolderERC20.getBalance(staker));
        console.log("Final stake balance::multicaller", stakeHolderERC20.getBalance(address(multicall3)));
        console.log("WETH in stake contract:", weth.balanceOf(address(stakeHolderERC20)));

        // Verify the ETH was converted to WETH and then staked
        assertEq(address(staker).balance, 900 ether); // 1000 - 100 ETH
        assertEq(weth.balanceOf(staker), 0); // All WETH should be staked
        assertGt(weth.balanceOf(address(multicall3)), 0);
        assertEq(weth.balanceOf(address(multicall3)), 100 ether);
    }

    function testFailWithoutApproval() public {
        uint256 stakeAmount = 100 ether;

        // Convert ETH to WETH first
        vm.startPrank(staker);

        // First deposit ETH to get WETH
        Multicall3.Call3Value[] memory callsWithValue = new Multicall3.Call3Value[](1);
        callsWithValue[0] = Multicall3.Call3Value({
            target: address(weth),
            allowFailure: false,
            value: stakeAmount,
            callData: abi.encodeWithSignature("deposit()")
        });

        multicall3.aggregate3Value{value: stakeAmount}(callsWithValue);

        // Try to stake WITHOUT approval - this should fail
        Multicall3.Call3[] memory calls = new Multicall3.Call3[](1);
        calls[0] = Multicall3.Call3({
            target: address(stakeHolderERC20),
            allowFailure: false, // We want this to fail the test
            callData: abi.encodeWithSignature(
                "stake(uint256)",
                stakeAmount
            )
        });

        // This should fail because we haven't approved the StakeHolderERC20 contract
        // to transfer WETH tokens from the staker
        multicall3.aggregate3(calls);

        vm.stopPrank();
    }
}
