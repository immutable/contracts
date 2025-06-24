// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
// solhint-disable not-rely-on-time

pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";

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
}
