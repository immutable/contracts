// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
// solhint-disable not-rely-on-time

pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBaseV2} from "../../contracts/staking/StakeHolderBaseV2.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";
import {StakeHolderERC20V2} from "../../contracts/staking/StakeHolderERC20V2.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";
import {StakeHolderNativeV2} from "../../contracts/staking/StakeHolderNativeV2.sol";
import {StakeHolderWIMX} from "../../contracts/staking/StakeHolderWIMX.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";
import {WIMX} from "../../contracts/staking/WIMX.sol";
import {ERC20PresetFixedSupply} from "openzeppelin-contracts-4.9.3/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract StakeHolderBaseTest is Test {

    bytes32 public defaultAdminRole;
    bytes32 public upgradeRole;
    bytes32 public distributeRole;

    IStakeHolder public stakeHolder;

    address public roleAdmin;
    address public upgradeAdmin;
    address public distributeAdmin;

    address public staker1;
    address public staker2;
    address public staker3;
    address public bank;

    ERC20PresetFixedSupply erc20;
    WIMX wimxErc20;


    function setUp() public virtual {
        roleAdmin = makeAddr("RoleAdmin");
        upgradeAdmin = makeAddr("UpgradeAdmin");
        distributeAdmin = makeAddr("DistributeAdmin");

        staker1 = makeAddr("Staker1");
        staker2 = makeAddr("Staker2");
        staker3 = makeAddr("Staker3");
        bank = makeAddr("bank");

        StakeHolderNative temp = new StakeHolderNative();
        defaultAdminRole = temp.DEFAULT_ADMIN_ROLE();
        upgradeRole = temp.UPGRADE_ROLE();
        distributeRole = temp.DISTRIBUTE_ROLE();
    }

    function deployERC20() internal {
        erc20 = new ERC20PresetFixedSupply("Name", "SYM", 1000 ether, bank);
    }

    function deployWIMX() internal {
        wimxErc20 = new WIMX();
    }

    function deployStakeHolderNativeV1() internal {
        StakeHolderNative impl = new StakeHolderNative();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderNative.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function deployStakeHolderERC20V1() internal {
        StakeHolderERC20 impl = new StakeHolderERC20();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, address(erc20)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function deployStakeHolderWIMXV1() internal {
        StakeHolderWIMX impl = new StakeHolderWIMX();
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMX.initialize.selector, roleAdmin, upgradeAdmin, distributeAdmin, address(wimxErc20)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = IStakeHolder(address(proxy));
    }

    function upgradeToStakeHolderNativeV2() internal {
        StakeHolderNativeV2 implV2 = new StakeHolderNativeV2();
        bytes memory upgradeData = abi.encodeWithSelector(StakeHolderBaseV2.upgradeStorage.selector, bytes("NotUsed"));
        vm.prank(upgradeAdmin);
        StakeHolderNativeV2(address(stakeHolder)).upgradeToAndCall(address(implV2), upgradeData);
    }

    function upgradeToStakeHolderERC20V2() internal {
        StakeHolderERC20V2 implV2 = new StakeHolderERC20V2();
        bytes memory upgradeData = abi.encodeWithSelector(StakeHolderBaseV2.upgradeStorage.selector, bytes("NotUsed"));
        vm.prank(upgradeAdmin);
        StakeHolderERC20V2(address(stakeHolder)).upgradeToAndCall(address(implV2), upgradeData);
    }

    function upgradeToStakeHolderWIMXV2() internal {
        StakeHolderWIMXV2 implV2 = new StakeHolderWIMXV2();
        bytes memory upgradeData = abi.encodeWithSelector(StakeHolderBaseV2.upgradeStorage.selector, bytes("NotUsed"));
        vm.prank(upgradeAdmin);
        StakeHolderWIMXV2(payable(address(stakeHolder))).upgradeToAndCall(address(implV2), upgradeData);
    }
}
