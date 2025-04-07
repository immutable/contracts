// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
// solhint-disable not-rely-on-time

pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {StakeHolder} from "../../contracts/staking/StakeHolder.sol";

import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";

contract StakeHolderBaseTest is Test {
    bytes32 public defaultAdminRole;
    bytes32 public upgradeRole;

    ERC1967Proxy public proxy;
    StakeHolder public stakeHolder;

    address public roleAdmin;
    address public upgradeAdmin;

    address public staker1;
    address public staker2;
    address public staker3;
    address public bank;

    function setUp() public {
        roleAdmin = makeAddr("RoleAdmin");
        upgradeAdmin = makeAddr("UpgradeAdmin");

        staker1 = makeAddr("Staker1");
        staker2 = makeAddr("Staker2");
        staker3 = makeAddr("Staker3");
        bank = makeAddr("bank");

        StakeHolder impl = new StakeHolder();

        bytes memory initData = abi.encodeWithSelector(StakeHolder.initialize.selector, roleAdmin, upgradeAdmin);

        proxy = new ERC1967Proxy(address(impl), initData);
        stakeHolder = StakeHolder(address(proxy));

        defaultAdminRole = stakeHolder.DEFAULT_ADMIN_ROLE();
        upgradeRole = stakeHolder.UPGRADE_ROLE();
    }
}
