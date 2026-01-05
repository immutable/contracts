// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {IStakeHolderV2} from "../../contracts/staking/IStakeHolderV2.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {StakeHolderOperationalBaseTestV2} from "./StakeHolderOperationalBaseV2.t.sol";
import {StakeHolderOperationalERC20Test} from "./StakeHolderOperationalERC20.t.sol";

contract StakeHolderOperationalERC20TestV2 is StakeHolderOperationalERC20Test, StakeHolderOperationalBaseTestV2 {
    function setUp() public override (StakeHolderOperationalERC20Test, StakeHolderBaseTest) {
        StakeHolderOperationalERC20Test.setUp();
        upgradeToStakeHolderERC20V2();
    }

    function _stakeFor(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal override {
        vm.prank(_distributor);
        erc20.approve(address(stakeHolder), _total);
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_distributor);
        IStakeHolderV2(address(stakeHolder)).stakeFor(_accountAmounts);
    }
}
