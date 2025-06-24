// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {StakeHolderNativeV2} from "../../contracts/staking/StakeHolderNativeV2.sol";
import {StakeHolderBaseV2} from "../../contracts/staking/StakeHolderBaseV2.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderConfigBaseTestV2} from "./StakeHolderConfigBaseV2.t.sol";

contract StakeHolderNativeV3a is StakeHolderNativeV2 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBaseV2) {
        version = 3;
    }
}


contract StakeHolderConfigNativeTestV2 is StakeHolderConfigBaseTestV2 {

    function setUp() public override {
        super.setUp();
        deployStakeHolderNativeV1();
        upgradeToStakeHolderNativeV2();
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNative()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNativeV2()));
    }

    function _deployV3() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNativeV3a()));
    }
}
