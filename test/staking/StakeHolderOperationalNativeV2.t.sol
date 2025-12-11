// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {IStakeHolderV2} from "../../contracts/staking/IStakeHolderV2.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";
import {StakeHolderOperationalBaseTestV2} from "./StakeHolderOperationalBaseV2.t.sol";
import {StakeHolderOperationalNativeTest} from "./StakeHolderOperationalNative.t.sol";

contract StakeHolderOperationalNativeTestV2 is StakeHolderOperationalNativeTest, StakeHolderOperationalBaseTestV2 {
    function setUp() public override (StakeHolderOperationalNativeTest, StakeHolderBaseTest) {
        StakeHolderOperationalNativeTest.setUp();
        upgradeToStakeHolderNativeV2();
    }

    function _stakeFor(address _distributor, uint256 _total, IStakeHolder.AccountAmount[] memory _accountAmounts, 
        bool _hasError, bytes memory _error) internal override {
        if (_hasError) {
            vm.expectRevert(_error);
        }
        vm.prank(_distributor);
        IStakeHolderV2(address(stakeHolder)).stakeFor{value: _total}(_accountAmounts);
    }
}
