// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderTimeDelayBaseTest} from "./StakeHolderTimeDelayBase.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";

contract StakeHolderWIMXV2 is StakeHolderWIMX {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBase) {
        version = 1;
    }
}


contract StakeHolderTimeDelayWIMXTest is StakeHolderTimeDelayBaseTest {

    function setUp() public override {
        super.setUp();
        deployWIMX();

        StakeHolderWIMX impl = new StakeHolderWIMX();

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMX.initialize.selector, address(stakeHolderTimeDelay), address(stakeHolderTimeDelay), 
                distributeAdmin, address(wimxErc20)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMXV2()));
    }
}
