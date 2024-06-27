// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata, ERC20TestCommon} from "./ERC20TestCommon.t.sol";
import {ImmutableERC20FixedSupplyNoBurnV2} from "contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurnV2.sol";

contract ImmutableERC20FixedSupplyNoBurnV2Test is ERC20TestCommon {

    ImmutableERC20FixedSupplyNoBurnV2 public erc20;

    function setUp() public virtual override {
        super.setUp();
        erc20 = new ImmutableERC20FixedSupplyNoBurnV2(admin, treasurer, hubOwner, name, symbol, supply);
        basicERC20 = IERC20Metadata(address(erc20));
    }

    function testInitExtended() public {
        assertEq(basicERC20.totalSupply(), supply, "supply");
        assertEq(basicERC20.balanceOf(treasurer), supply, "initial treasurer balance");
        assertEq(erc20.owner(), hubOwner, "Hub owner");

        assertTrue(erc20.hasRole(erc20.HUB_OWNER_ROLE(), hubOwner), "Hub owner");
        assertEq(erc20.getRoleMemberCount(erc20.HUB_OWNER_ROLE()), 1, "one hub owner");
        assertTrue(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), admin), "admin");
        assertEq(erc20.getRoleMemberCount(erc20.DEFAULT_ADMIN_ROLE()), 1, "one admin");
    }
}
