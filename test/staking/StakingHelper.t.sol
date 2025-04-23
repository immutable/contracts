// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {StakingHelper} from "../../contracts/staking/StakingHelper.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple ERC20 token for testing
contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Wrapped ETH implementation (simplified)
contract WIMX is ERC20 {
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

contract StakingHelperTest is Test {
    WIMX public wimx;
    StakeHolderERC20 public stakeHolder;
    StakingHelper public stakingHelper;

    address public admin;
    address public user;

    function setUp() public {
        // Setup addresses
        admin = makeAddr("admin");
        user = makeAddr("user");

        // Deploy WIMX token
        wimx = new WIMX();

        // Deploy StakeHolderERC20 with WIMX as the staking token
        stakeHolder = new StakeHolderERC20();
        stakeHolder.initialize(
            admin,  // role admin
            admin,  // upgrade admin
            admin,  // distribute admin
            address(wimx)
        );

        // Deploy StakingHelper
        stakingHelper = new StakingHelper(address(wimx), address(stakeHolder));

        // Give user some native tokens
        vm.deal(user, 1000 ether);
    }

    function testWrapAndStake() public {
        uint256 stakeAmount = 100 ether;

        // Verify initial conditions
        assertEq(stakeHolder.getBalance(address(stakingHelper)), 0);
        assertEq(stakeHolder.getBalance(address(user)), 0);
        assertEq(wimx.balanceOf(address(stakingHelper)), 0);
        assertEq(address(user).balance, 1000 ether);

        // User calls wrapAndStake with native tokens
        vm.prank(user);
        stakingHelper.wrapAndStake{value: stakeAmount}();

        // Verify the native tokens were converted to WIMX and staked
        assertEq(address(user).balance, 900 ether); // 1000 - 100 ETH
        assertEq(wimx.balanceOf(address(stakingHelper)), 0); // All WIMX should be staked

        // Important: The stake is recorded against the StakingHelper contract, not the user
        assertEq(stakeHolder.getBalance(address(stakingHelper)), stakeAmount);
        assertEq(stakeHolder.getBalance(user), 0); // User has no direct stake

        // Verify WIMX balance in the StakeHolder contract
        assertEq(wimx.balanceOf(address(stakingHelper)), 0);
    }

    function testDepositedWIMXIsOwnedByStakingHelper() public {
        uint256 stakeAmount = 100 ether;

        // Before depositing WIMX
        console.log("Initial balance::user", address(user).balance);
        console.log("Initial balance::stakingHelper", address(stakingHelper).balance);
        console.log("Initial WIMX balance::user", wimx.balanceOf(user));
        console.log("Initial WIMX balance::stakingHelper", wimx.balanceOf(address(stakingHelper)));

        vm.prank(user);
        stakingHelper.depositOnly{value: stakeAmount}();

        // Before depositing WIMX
        console.log("Final balance::user", address(user).balance);
        console.log("Final balance::stakingHelper", address(stakingHelper).balance);
        console.log("Final WIMX balance::user", wimx.balanceOf(user));
        console.log("Final WIMX balance::stakingHelper", wimx.balanceOf(address(stakingHelper)));

        // Verify the ETH was converted to WETH and then staked
        assertEq(address(user).balance, 900 ether); // 1000 - 100 ETH
        assertEq(wimx.balanceOf(user), 0); // All wimx should be staked
        assertGt(wimx.balanceOf(address(stakingHelper)), 0);
        assertEq(wimx.balanceOf(address(stakingHelper)), 100 ether);
    }

    // function testGetUserStake() public {
    //     uint256 stakeAmount = 100 ether;

    //     // User calls wrapAndStake
    //     vm.prank(user);
    //     stakingHelper.wrapAndStake{value: stakeAmount}();

    //     // The getUserStake function will return the stake of the StakingHelper contract
    //     assertEq(stakingHelper.getUserStake(address(stakingHelper)), stakeAmount);

    //     // The user doesn't have a direct stake
    //     assertEq(stakingHelper.getUserStake(user), 0);
    // }

    // function testEmitsStakingCompletedEvent() public {
    //     uint256 stakeAmount = 100 ether;

    //     // Expect the StakingCompleted event to be emitted
    //     vm.expectEmit(true, true, false, true);
    //     emit StakingHelper.StakingCompleted(user, stakeAmount, block.timestamp);

    //     // User calls wrapAndStake
    //     vm.prank(user);
    //     stakingHelper.wrapAndStake{value: stakeAmount}();
    // }
}
