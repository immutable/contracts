// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";
import {WIMX} from "../../contracts/staking/WIMX.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseV2} from "../../contracts/staking/StakeHolderBaseV2.sol";
import {StakeHolderConfigBaseTestV2} from "./StakeHolderConfigBaseV2.t.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

contract StakeHolderWIMXV3a is StakeHolderWIMXV2 {
    function upgradeStorage(bytes memory /* _data */) external override(StakeHolderBaseV2) {
        version = 3;
    }
}

contract StakeHolderConfigWIMXTestV2 is StakeHolderConfigBaseTestV2 {

    function setUp() public override {
        super.setUp();
        deployWIMX();
        deployStakeHolderWIMXV1();
        upgradeToStakeHolderWIMXV2();
    }

    function testDeployStakeHolderWIMXV2() public {
        // Check that V2 can be installed from scratch: that is, without upgrading form V1.
        StakeHolderWIMXV2 impl = new StakeHolderWIMXV2();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMXV2.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, wimxErc20
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        IStakeHolder stakeHolderV2 = IStakeHolder(address(proxy));

        assertEq(stakeHolderV2.version(), 2, "Incorrect version");
    }

    function _deployV1() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMX()));
    }

    function _deployV2() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMXV2()));
    }

    function _deployV3() internal override returns(IStakeHolder) {
        return IStakeHolder(address(new StakeHolderWIMXV3a()));
    }
}