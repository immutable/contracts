// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {StakeHolderERC20V2} from "../../contracts/staking/StakeHolderERC20V2.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderBaseV2} from "../../contracts/staking/StakeHolderBaseV2.sol";
import {StakeHolderConfigBaseTestV2} from "./StakeHolderConfigBaseV2.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

contract StakeHolderERC20V3a is StakeHolderERC20V2 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBaseV2) {
        version = 3;
    }
}

contract StakeHolderConfigERC20TestV2 is StakeHolderConfigBaseTestV2 {

    function setUp() public override {
        super.setUp();
        deployERC20();
        deployStakeHolderERC20V1();
        upgradeToStakeHolderERC20V2();
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V2()));
    }

    function _deployV3() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V3a()));
    }
}