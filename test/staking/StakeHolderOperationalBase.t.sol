// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {stdError} from "forge-std/StdError.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";

abstract contract StakeHolderOperationalBaseTest is StakeHolderBaseTest {
    function testStake() public {
        _deal(staker1, 100 ether);
        _addStake(staker1, 10 ether);
        assertEq(_getBalanceStaker(staker1), 90 ether, "Incorrect balance1");
        assertEq(_getBalanceStakeHolderContract(), 10 ether, "Incorrect balance2");

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance3");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
        address[] memory stakers = stakeHolder.getStakers(0, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker");
    }

    function testStakeTwice() public {
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker1, 20 ether);

        assertEq(stakeHolder.getBalance(staker1), 30 ether, "Incorrect balance");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
    }

    function testStakeZeroValue() public {
        _addStake(staker1, 0 ether, abi.encodeWithSelector(IStakeHolder.MustStakeMoreThanZero.selector));
    }

    function testMultipleStakers() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

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
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        vm.prank(staker1);
        stakeHolder.unstake(10 ether);

        assertEq(_getBalanceStaker(staker1), 100 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 0 ether, "Incorrect balance");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
        address[] memory stakers = stakeHolder.getStakers(0, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker");
    }

    function testUnstakeTooMuch() public {
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.UnstakeAmountExceedsBalance.selector, 11 ether, 10 ether));
        vm.prank(staker1);
        stakeHolder.unstake(11 ether);
    }

    function testUnstakePartial() public {
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        vm.prank(staker1);
        stakeHolder.unstake(3 ether);

        assertEq(_getBalanceStaker(staker1), 93 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 7 ether, "Incorrect balance");
    }

    function testUnstakeMultiple() public {
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        vm.prank(staker1);
        stakeHolder.unstake(3 ether);
        vm.prank(staker1);
        stakeHolder.unstake(1 ether);

        assertEq(_getBalanceStaker(staker1), 94 ether, "Incorrect native balance");
        assertEq(stakeHolder.getBalance(staker1), 6 ether, "Incorrect balance");
    }

    function testRestaking() public {
        _deal(staker1, 100 ether);

        _addStake(staker1, 10 ether);
        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        vm.prank(staker1);
        stakeHolder.unstake(10 ether);
        assertEq(stakeHolder.getBalance(staker1), 0 ether, "Incorrect balance2");
        _addStake(staker1, 9 ether);
        assertEq(stakeHolder.getBalance(staker1), 9 ether, "Incorrect balance3");
        _addStake(staker1,2 ether);
        assertEq(stakeHolder.getBalance(staker1), 11 ether, "Incorrect balance4");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
        vm.stopPrank();
    }

    function testGetStakers() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        address[] memory stakers = stakeHolder.getStakers(0, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker1, "Incorrect staker1");

        stakers = stakeHolder.getStakers(1, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker2, "Incorrect staker2");

        stakers = stakeHolder.getStakers(2, 1);
        assertEq(stakers.length, 1, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker3, "Incorrect staker3");

        stakers = stakeHolder.getStakers(1, 2);
        assertEq(stakers.length, 2, "Incorrect length returned by getStakers");
        assertEq(stakers[0], staker2, "Incorrect staker2");
        assertEq(stakers[1], staker3, "Incorrect staker3");
    }

    function testGetStakersOutOfRange() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        vm.expectRevert(stdError.indexOOBError);
        stakeHolder.getStakers(1, 3);
    }    

    function testDistributeRewardsOne() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        // Distribute rewards to staker2 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker2, 0.5 ether);
        _distributeRewards(distributeAdmin, 0.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertEq(stakeHolder.getBalance(staker2), 20.5 ether, "Incorrect balance2");
        assertEq(stakeHolder.getBalance(staker3), 30 ether, "Incorrect balance3");
    }

    function testDistributeRewardsMultiple() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        // Distribute rewards to staker2 and staker3.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](2);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker2, 0.5 ether);
        accountsAmounts[1] = IStakeHolder.AccountAmount(staker3, 1 ether);
        _distributeRewards(distributeAdmin, 1.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertEq(stakeHolder.getBalance(staker2), 20.5 ether, "Incorrect balance2");
        assertEq(stakeHolder.getBalance(staker3), 31 ether, "Incorrect balance3");
    }

    function testDistributeZeroReward() public {
        _deal(staker1, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);

        // Distribute rewards of 0 to staker1.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0 ether);
        _distributeRewards(distributeAdmin, 0 ether, accountsAmounts, 
            abi.encodeWithSelector(IStakeHolder.MustDistributeMoreThanZero.selector));
    }

    function testDistributeToEmptyAccount() public {
        _deal(staker1, 100 ether);
        _deal(distributeAdmin, 100 ether);

        uint256 amount = 10 ether;
        _addStake(staker1, amount);
        vm.prank(staker1);
        stakeHolder.unstake(amount);

        // Distribute rewards to staker2 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _distributeRewards(distributeAdmin, 0.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 0.5 ether, "Incorrect balance1");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
    }

    function testDistributeToUnusedAccount() public {
        _deal(distributeAdmin, 100 ether);

        // Distribute rewards to staker2 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _distributeRewards(distributeAdmin, 0.5 ether, accountsAmounts,
            abi.encodeWithSelector(IStakeHolder.AttemptToDistributeToNewAccount.selector, staker1, 0.5 ether));
    }

    function testDistributeBadAuth() public {
        _deal(staker1, 100 ether);
        _deal(bank, 100 ether);

        _addStake(staker1, 10 ether);

        // Distribute rewards to staker1 only, but not from distributeAdmin
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _distributeRewards(bank, 0.5 ether, accountsAmounts, 
            abi.encodePacked("AccessControl: account 0x3448fc79c22032be61bee8d832ebc59744f5cc40 is missing role 0x444953545249425554455f524f4c450000000000000000000000000000000000"));
    }


    function _deal(address _to, uint256 _amount) internal virtual;
    function _getBalanceStaker(address _staker) internal virtual view returns (uint256);
    function _getBalanceStakeHolderContract() internal virtual view returns (uint256);

    function _addStake(address _staker, uint256 _amount) internal {
        _addStake(_staker, _amount, false, bytes(""));
    }
    function _addStake(address _staker, uint256 _amount, bytes memory _error) internal {
        _addStake(_staker, _amount, true, _error);

    }
    function _addStake(address _staker, uint256 _amount, bool _hasError, bytes memory _error) internal virtual;


    function _distributeRewards(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts) internal {
        _distributeRewards(_distributor, _total, _accountAmounts, false, bytes(""));
    }
    function _distributeRewards(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, bytes memory _error) internal {
        _distributeRewards(_distributor, _total, _accountAmounts, true, _error);
    }
    function _distributeRewards(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal virtual;
}
