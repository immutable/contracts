// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";

contract StakeHolderNativeV2a is StakeHolderNative {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 2;
    }
}


contract StakeHolderConfigNativeTest is StakeHolderConfigBaseTest {

    function setUp() public override {
        super.setUp();
        deployStakeHolderNativeV1();
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNative()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNativeV2a()));
    }

}
