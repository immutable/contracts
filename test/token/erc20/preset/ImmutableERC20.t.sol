// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ImmutableERC20} from "contracts/token/erc20/preset/ImmutableERC20.sol";
import {IImmutableERC20Errors} from "contracts/errors/ERC20Errors.sol";


contract ImmutableERC20Test is Test {

    ImmutableERC20 public erc20;

    address public minter;
    address public hubOwner;
    string name;
    string symbol;
    uint256 supply;

    function setUp() public virtual {
        hubOwner = makeAddr("hubOwner");
        minter = makeAddr("minterRole");
        name = "HappyToken";
        symbol = "HPY";

        erc20 = new ImmutableERC20(name, symbol, hubOwner, minter);
    }

    function testInit() public {
        assertEq(erc20.name(), name, "name");
        assertEq(erc20.symbol(), symbol, "symbol");
        assertEq(erc20.owner(), hubOwner, "Hub owner");
        bytes32 minterRole = erc20.MINTER_ROLE();
        assertTrue(erc20.hasRole(minterRole, minter));
        bytes32 adminRole = erc20.DEFAULT_ADMIN_ROLE();
        assertTrue(erc20.hasRole(adminRole, hubOwner));
    }

    function testChangeOwner() public {
        address newOwner = makeAddr("newOwner");
        vm.prank(hubOwner);
        erc20.transferOwnership(newOwner);
        assertEq(erc20.owner(), newOwner, "new owner");
    }

    function testRenounceOwnerBlocked() public {
        vm.prank(hubOwner);
        vm.expectRevert(abi.encodeWithSelector(IImmutableERC20Errors.RenounceOwnershipNotAllowed.selector));
        erc20.renounceOwnership();
    }

    function testOnlyMinterCanMint() public {
        address to = makeAddr("to");
        uint256 amount = 100;
        vm.prank(hubOwner);
        vm.expectRevert("AccessControl: account 0xa268ae5516b47694c3f15805a560258dbcdefd08 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc20.mint(to, amount);
    }

    function testMint() public {
        address to = makeAddr("to");
        uint256 amount = 100;
        vm.prank(minter);
        erc20.mint(to, amount);
        assertEq(erc20.balanceOf(to), amount);
    }

    function testBurn() public {
        address from = makeAddr("from");
        uint256 amount = 100;
        vm.prank(minter);
        erc20.mint(from, amount);
        assertEq(erc20.balanceOf(from), 100);
        erc20.burn(from, amount);
        assertEq(erc20.balanceOf(from), 0);
    }

}
