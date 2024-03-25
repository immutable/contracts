// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ImmutableERC20FixedSupply} from "contracts/token/erc20/ImmutableERC20FixedSupply.sol";


contract ImmutableERC20FixedSupplyTest is Test {

    ImmutableERC20FixedSupply public erc20;

    address public owner;

    function setUp() public virtual {
        owner = makeAddr("owner");
    }

    function testInit() public {
        string memory name = "HappyToken";
        string memory symbol = "HPY";
        uint256 supply = 1000000;

        erc20 = new ImmutableERC20FixedSupply(name, symbol, supply, owner);
        assertEq(erc20.name(), name, "name");
        assertEq(erc20.symbol(), symbol, "symbol");
        assertEq(erc20.totalSupply(), supply, "supply");
        assertEq(erc20.balanceOf(owner), supply, "initial owner balance");
    }
}
