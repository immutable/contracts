// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderOperationalBaseTest} from "./StakeHolderOperationalBase.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20PresetFixedSupply} from "openzeppelin-contracts-4.9.3/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract StakeHolderOperationalERC20Test is StakeHolderOperationalBaseTest {
    ERC20PresetFixedSupply erc20;


    function setUp() public override {
        super.setUp();

        erc20 = new ERC20PresetFixedSupply("Name", "SYM", 1000 ether, bank);

        StakeHolderERC20 impl = new StakeHolderERC20();

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, address(erc20)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function _deal(address _to, uint256 _amount) internal override {
        vm.prank(bank);
        erc20.transfer(_to, _amount);
    }

    function _addStake(address _staker, uint256 _amount, bool _hasError, bytes memory _error) internal override {
        vm.prank(_staker);
        erc20.approve(address(stakeHolder), _amount);
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_staker);
        stakeHolder.stake(_amount);
    }
    function _distributeRewards(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal override {
        vm.prank(_distributor);
        erc20.approve(address(stakeHolder), _total);
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_distributor);
        stakeHolder.distributeRewards(_accountAmounts);
    }
    function _getBalance(address _staker) internal view override returns (uint256) {
        return erc20.balanceOf(_staker);
    }

}
