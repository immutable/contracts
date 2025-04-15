// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderConfigBaseTest} from "./StakeHolderConfigBase.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

contract StakeHolderERC20V2 is StakeHolderERC20 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 1;
    }
}

contract StakeHolderConfigERC20Test is StakeHolderConfigBaseTest {

    function setUp() public override {
        super.setUp();

        StakeHolderERC20 impl = new StakeHolderERC20();

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, address(0)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V2()));
    }
}