// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ImmutableERC20MinterBurnerPermit} from "contracts/token/erc20/preset/ImmutableERC20MinterBurnerPermit.sol";
import {IImmutableERC20Errors} from "contracts/token/erc20/preset/Errors.sol";

contract ImmutableERC20MinterBurnerPermitTest is Test {
    ImmutableERC20MinterBurnerPermit public erc20;

    address public minter;
    address public hubOwner;
    address public tokenReceiver;
    address public admin;
    string name;
    string symbol;
    uint256 maxSupply;

    function setUp() public virtual {
        hubOwner = makeAddr("hubOwner");
        minter = makeAddr("minterRole");
        tokenReceiver = makeAddr("tokenReceiver");
        admin = makeAddr("admin");
        name = "HappyToken";
        symbol = "HPY";
        maxSupply = 1000;

        erc20 = new ImmutableERC20MinterBurnerPermit(admin, minter, hubOwner, name, symbol, maxSupply);
    }

    function testInit() public {
        assertEq(erc20.name(), name, "name");
        assertEq(erc20.symbol(), symbol, "symbol");
        bytes32 minterRole = erc20.MINTER_ROLE();
        assertTrue(erc20.hasRole(minterRole, minter));
        bytes32 adminRole = erc20.DEFAULT_ADMIN_ROLE();
        assertTrue(erc20.hasRole(adminRole, admin));
        assertEq(erc20.cap(), maxSupply, "total supply");
        assertTrue(erc20.hasRole(erc20.HUB_OWNER_ROLE(), hubOwner), "hub owner");
    }

    function testRenounceLastHubOwnerBlocked() public {
        vm.prank(hubOwner);
        bytes32 hubRole = erc20.HUB_OWNER_ROLE();
        vm.expectRevert(abi.encodeWithSelector(IImmutableERC20Errors.RenounceOwnershipNotAllowed.selector));
        erc20.renounceRole(hubRole, hubOwner);
    }

    function testRenounceLastAdminBlocked() public {
        vm.prank(admin);
        bytes32 adminRole = erc20.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(abi.encodeWithSelector(IImmutableERC20Errors.RenounceOwnershipNotAllowed.selector));
        erc20.renounceRole(adminRole, admin);
    }

    function testRenounceAdmin() public {
        address secondAdmin = makeAddr("secondAdmin");
        vm.startPrank(admin);
        erc20.grantRole(erc20.DEFAULT_ADMIN_ROLE(), secondAdmin);
        assertTrue(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), secondAdmin));
        vm.stopPrank();

        vm.startPrank(admin);
        erc20.renounceRole(erc20.DEFAULT_ADMIN_ROLE(), admin);
        assertFalse(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), admin));
        vm.stopPrank();
    }

    function testRenounceHubOwner() public {
        address secondHubOwner = makeAddr("secondHubOwner");
        vm.startPrank(admin);
        erc20.grantRole(erc20.HUB_OWNER_ROLE(), secondHubOwner);
        assertTrue(erc20.hasRole(erc20.HUB_OWNER_ROLE(), secondHubOwner));
        vm.stopPrank();

        vm.startPrank(hubOwner);
        erc20.renounceRole(erc20.HUB_OWNER_ROLE(), hubOwner);
        assertFalse(erc20.hasRole(erc20.HUB_OWNER_ROLE(), hubOwner));
        vm.stopPrank();
    }

    function testOnlyMinterCanMint() public {
        address to = makeAddr("to");
        uint256 amount = 100;
        vm.prank(hubOwner);
        vm.expectRevert(
            "AccessControl: account 0xa268ae5516b47694c3f15805a560258dbcdefd08 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000"
        );
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
        uint256 amount = 100;
        vm.prank(minter);
        erc20.mint(tokenReceiver, amount);
        assertEq(erc20.balanceOf(tokenReceiver), 100);
        vm.prank(tokenReceiver);
        erc20.burn(amount);
        assertEq(erc20.balanceOf(tokenReceiver), 0);
    }

    function testCanOnlyMintUpToMaxSupply() public {
        address to = makeAddr("to");
        uint256 amount = 1000;
        vm.startPrank(minter);
        erc20.mint(to, amount);
        assertEq(erc20.balanceOf(to), amount);
        vm.expectRevert("ERC20Capped: cap exceeded");
        erc20.mint(to, 1);
        vm.stopPrank();
    }

    function testBurnFrom() public {
        uint256 amount = 100;
        address operator = makeAddr("operator");
        vm.prank(minter);
        erc20.mint(tokenReceiver, amount);
        assertEq(erc20.balanceOf(tokenReceiver), 100);
        vm.prank(tokenReceiver);
        erc20.increaseAllowance(operator, amount);
        vm.prank(operator);
        erc20.burnFrom(tokenReceiver, amount);
        assertEq(erc20.balanceOf(tokenReceiver), 0);
    }

    function testPermit() public {
        uint256 ownerPrivateKey = 1;
        uint256 spenderPrivateKey = 2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);

        bytes32 PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

        uint256 value = 1e18;

        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = erc20.nonces(owner);
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 hash = erc20.DOMAIN_SEPARATOR();
        hash = keccak256(abi.encodePacked("\x19\x01", hash, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        vm.startPrank(owner);
        erc20.permit(owner, spender, value, deadline, v, r, s);
        vm.stopPrank();

        assertEq(erc20.allowance(owner, spender), value);
    }
}
