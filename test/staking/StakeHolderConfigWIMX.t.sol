// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import {Test} from "forge-std/Test.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";

contract StakeHolderWIMXV2a is StakeHolderWIMX {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 2;
    }
}

contract StakeHolderConfigWIMXTest is StakeHolderConfigBaseTest {

    function setUp() public override {
        super.setUp();
        deployWIMX();
        deployStakeHolderWIMXV1();
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMX()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMXV2a()));
    }
}