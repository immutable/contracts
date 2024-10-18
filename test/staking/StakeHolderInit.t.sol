// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolder} from "../../contracts/staking/StakeHolder.sol";
import {StakeHolderBaseTest} from "./StakeHolderBase.t.sol";

contract StakeHolderInitTest is StakeHolderBaseTest {
    function testGetVersion() public {
        uint256 ver = stakeHolder.version();
        assertEq(ver, 0, "Expect initial version of storage layout to be V0");
    }

    function testStakersInit() public {
        assertEq(stakeHolder.getNumStakers(), 0, "Expect no stakers at deployment time");
    }

    function testAdmins() public {
        assertEq(stakeHolder.getRoleMemberCount(defaultAdminRole), 1, "Expect one role admin");
        assertEq(stakeHolder.getRoleMemberCount(upgradeRole), 1, "Expect one upgrade admin");
        assertTrue(stakeHolder.hasRole(defaultAdminRole, roleAdmin), "Expect roleAdmin is role admin");
        assertTrue(stakeHolder.hasRole(upgradeRole, upgradeAdmin), "Expect upgradeAdmin is upgrade admin");
    }
}
