// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "forge-std/Test.sol";

abstract contract ERC20TestCommon is Test {
    address public admin;
    address public treasurer;
    address public hubOwner;
    string public name;
    string public symbol;
    uint256 public supply;

    IERC20Metadata basicERC20;

    function setUp() public virtual {
        admin = makeAddr("admin");
        hubOwner = makeAddr("hubOwner");
        treasurer = makeAddr("treasurer");
        name = "HappyToken";
        symbol = "HPY";
        supply = 1000000;
    }

    function testInit() public {
        assertEq(basicERC20.name(), name, "name");
        assertEq(basicERC20.symbol(), symbol, "symbol");
        assertEq(basicERC20.balanceOf(hubOwner), 0, "initial hub owner balance");
    }
}
