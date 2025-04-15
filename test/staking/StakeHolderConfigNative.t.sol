// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

contract StakeHolderNativeV2 is StakeHolderNative {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 1;
    }
}


contract StakeHolderConfigNativeTest is StakeHolderConfigBaseTest {

    function setUp() public override {
        super.setUp();

        StakeHolderNative impl = new StakeHolderNative();

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderNative.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNative()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderNativeV2()));
    }

}
