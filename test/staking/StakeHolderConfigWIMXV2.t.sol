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

        // Deploy V1
        StakeHolderWIMX impl = new StakeHolderWIMX();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMX.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, address(0)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));

        // Upgrade to V2
        StakeHolderWIMXV2 implV2 = new StakeHolderWIMXV2();
        bytes memory upgradeData = abi.encodeWithSelector(StakeHolderBaseV2.upgradeStorage.selector, bytes("NotUsed"));
        vm.prank(upgradeAdmin);
        StakeHolderWIMXV2(payable(address(stakeHolder))).upgradeToAndCall(address(implV2), upgradeData);

        assertEq(stakeHolder.version(), 2, "Wrong version");
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