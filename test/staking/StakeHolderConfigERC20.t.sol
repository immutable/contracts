// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";

contract StakeHolderERC20V2a is StakeHolderERC20 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 2;
    }
}

contract StakeHolderConfigERC20Test is StakeHolderConfigBaseTest {

    function setUp() public override {
        super.setUp();
        deployERC20();
        deployStakeHolderERC20V1();
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V2a()));
    }
}