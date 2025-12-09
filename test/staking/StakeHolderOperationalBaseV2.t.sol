// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderOperationalBaseTest} from "./StakeHolderOperationalBase.t.sol";

abstract contract StakeHolderOperationalBaseTestV2 is StakeHolderOperationalBaseTest {
    function testStakeForOne() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        // Stake for staker2 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker2, 0.5 ether);
        _stakeFor(distributeAdmin, 0.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertEq(stakeHolder.getBalance(staker2), 20.5 ether, "Incorrect balance2");
        assertEq(stakeHolder.getBalance(staker3), 30 ether, "Incorrect balance3");
    }

    function testStakeForMultiple() public {
        _deal(staker1, 100 ether);
        _deal(staker2, 100 ether);
        _deal(staker3, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);
        _addStake(staker2, 20 ether);
        _addStake(staker3, 30 ether);

        // Stake for staker2 and staker3.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](2);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker2, 0.5 ether);
        accountsAmounts[1] = IStakeHolder.AccountAmount(staker3, 1 ether);
        _stakeFor(distributeAdmin, 1.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 10 ether, "Incorrect balance1");
        assertEq(stakeHolder.getBalance(staker2), 20.5 ether, "Incorrect balance2");
        assertEq(stakeHolder.getBalance(staker3), 31 ether, "Incorrect balance3");
    }

    function testStakeForZeroReward() public {
        _deal(staker1, 100 ether);
        _deal(distributeAdmin, 100 ether);

        _addStake(staker1, 10 ether);

        // Stake for of 0 to staker1.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0 ether);
        _stakeFor(distributeAdmin, 0 ether, accountsAmounts, 
            abi.encodeWithSelector(IStakeHolder.MustDistributeMoreThanZero.selector));
    }

    function testStakeForToEmptyAccount() public {
        _deal(staker1, 100 ether);
        _deal(distributeAdmin, 100 ether);

        uint256 amount = 10 ether;
        _addStake(staker1, amount);
        vm.prank(staker1);
        stakeHolder.unstake(amount);

        // Stake for to staker1 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _stakeFor(distributeAdmin, 0.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 0.5 ether, "Incorrect balance1");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
    }

    function testStakeForToUnusedAccount() public {
        _deal(distributeAdmin, 100 ether);

        // Stake for to staker1 only.
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _stakeFor(distributeAdmin, 0.5 ether, accountsAmounts);

        assertEq(stakeHolder.getBalance(staker1), 0.5 ether, "Incorrect balance1");
        assertTrue(stakeHolder.hasStaked(staker1), "Expect staker1 has staked");
        assertEq(stakeHolder.getNumStakers(), 1, "Incorrect number of stakers");
    }

    function testStakeForBadAuth() public {
        _deal(staker1, 100 ether);
        _deal(bank, 100 ether);

        _addStake(staker1, 10 ether);

        // Distribute rewards to staker1 only, but not from distributeAdmin
        IStakeHolder.AccountAmount[] memory accountsAmounts = new IStakeHolder.AccountAmount[](1);
        accountsAmounts[0] = IStakeHolder.AccountAmount(staker1, 0.5 ether);
        _stakeFor(bank, 0.5 ether, accountsAmounts, 
            abi.encodePacked("AccessControl: account 0x3448fc79c22032be61bee8d832ebc59744f5cc40 is missing role 0x444953545249425554455f524f4c450000000000000000000000000000000000"));
    }

    function _stakeFor(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts) internal {
        _stakeFor(_distributor, _total, _accountAmounts, false, bytes(""));
    }
    function _stakeFor(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, bytes memory _error) internal {
        _stakeFor(_distributor, _total, _accountAmounts, true, _error);
    }
    function _stakeFor(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal virtual;
}
