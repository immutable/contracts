// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ImmutableERC20FixedSupplyNoBurn} from "contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol";

contract ImmutableERC20FixedSupplyNoBurnTest is Test {

    ImmutableERC20FixedSupplyNoBurn public erc20;

    address public admin;
    address public treasurer;
    address public hubOwner;
    string name;
    string symbol;
    uint256 supply;

    function setUp() public virtual {
        admin = makeAddr("admin");
        hubOwner = makeAddr("hubOwner");
        treasurer = makeAddr("treasurer");
        name = "HappyToken";
        symbol = "HPY";
        supply = 1000000;

        erc20 = new ImmutableERC20FixedSupplyNoBurn(admin, treasurer, hubOwner, name, symbol, supply);
    }

    function testInit() public {
        assertEq(erc20.name(), name, "name");
        assertEq(erc20.symbol(), symbol, "symbol");
        assertEq(erc20.totalSupply(), supply, "supply");
        assertEq(erc20.balanceOf(treasurer), supply, "initial treasurer balance");
        assertEq(erc20.balanceOf(hubOwner), 0, "initial hub owner balance");
        assertEq(erc20.balanceOf(admin), 0, "initial admin balance");
        assertTrue(erc20.hasRole(erc20.HUB_OWNER_ROLE(), hubOwner), "Hub owner");
        assertEq(erc20.getRoleMemberCount(erc20.HUB_OWNER_ROLE()), 1, "one hub owner");
        assertTrue(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), admin), "admin");
        assertEq(erc20.getRoleMemberCount(erc20.DEFAULT_ADMIN_ROLE()), 1, "one admin");
    }
}
