// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {StakeHolderERC20V2} from "../../contracts/staking/StakeHolderERC20V2.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderTimeDelayBaseTest} from "./StakeHolderTimeDelayBase.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20PresetFixedSupply} from "openzeppelin-contracts-4.9.3/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {StakeHolderBaseV2} from "../../contracts/staking/StakeHolderBaseV2.sol";

contract StakeHolderERC20V3a is StakeHolderERC20V2 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBaseV2) {
        version = 3;
    }
}


contract StakeHolderTimeDelayERC20Test is StakeHolderTimeDelayBaseTest {

    function setUp() public override {
        super.setUp();
        deployERC20();

        StakeHolderERC20 impl = new StakeHolderERC20();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, address(stakeHolderTimeDelay), address(stakeHolderTimeDelay), 
                distributeAdmin, address(erc20)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V2()));
    }

    function _deployV3() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderERC20V3a()));
    }
}
