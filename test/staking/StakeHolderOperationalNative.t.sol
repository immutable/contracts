// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import {Test} from "forge-std/Test.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderOperationalBaseTest} from "./StakeHolderOperationalBase.t.sol";
import {StakeHolderAttackWallet} from "./StakeHolderAttackWallet.sol";
import {StakeHolderAttackWallet2} from "./StakeHolderAttackWallet2.sol";

contract StakeHolderOperationalNativeTest is StakeHolderOperationalBaseTest {

    function setUp() public virtual override {
        super.setUp();
        deployStakeHolderNativeV1();
    }

    function testUnstakeReentrantAttack() public {
        StakeHolderAttackWallet attacker = new StakeHolderAttackWallet(address(stakeHolder));
        _deal(address(attacker), 100 ether);

        attacker.stake(10 ether);
        // Attacker's reentracy attack will double the amount being unstaked.
        // The attack fails due to attempting to withdraw more than balance (that is, 2 x 6 eth = 12)
        vm.expectRevert(abi.encodePacked("ReentrancyGuard: reentrant call"));
        attacker.unstake{gas: 10000000}(6 ether);
    }

    function testWillFailToAcceptTransferDuringUnstake() public {
        StakeHolderAttackWallet2 attacker = new StakeHolderAttackWallet2(address(stakeHolder));
        _deal(address(attacker), 100 ether);

        attacker.stake(10 ether);

        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.UnstakeTransferFailed.selector));
        attacker.unstake{gas: 10000000}(6 ether);
    }

    function testDistributeMismatch() public {
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
        _distributeRewards(distributeAdmin, 1 ether, accountsAmounts,
            abi.encodeWithSelector(IStakeHolder.MismatchMsgValueAmount.selector, 1 ether, 1.5 ether));
    }

    function testAddStakeMismatch() public {
        uint256 amount = 100 ether;
        _deal(staker1, amount);
        vm.prank(staker1);
        vm.expectRevert(abi.encodeWithSelector(IStakeHolder.MismatchMsgValueAmount.selector, amount, amount+1));
        stakeHolder.stake{value: amount}(amount + 1);
    }

    function _deal(address _to, uint256 _amount) internal override {
        vm.deal(_to, _amount);
    }
    function _addStake(address _staker, uint256 _amount, bool _hasError, bytes memory _error) internal override {
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_staker);
        stakeHolder.stake{value: _amount}(_amount);
    }
    function _distributeRewards(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal override {
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_distributor);
        stakeHolder.distributeRewards{value: _total}(_accountAmounts);
    }
    function _getBalanceStaker(address _staker) internal view override returns (uint256) {
        return _staker.balance;
    }
    function _getBalanceStakeHolderContract() internal view override returns (uint256) {
        return address(stakeHolder).balance;
    }

}
