// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata, ERC20TestCommon} from "./ERC20TestCommon.t.sol";
import {ImmutableERC20MinterBurnerPermit} from "contracts/token/erc20/preset/ImmutableERC20MinterBurnerPermit.sol";

abstract contract ERC20MinterBurnerPermitCommonTest is ERC20TestCommon {

    ImmutableERC20MinterBurnerPermit public erc20;

    address public minter;
    address public tokenReceiver;

    function setUp() public virtual override {
        super.setUp();
        minter = makeAddr("minterRole");
        tokenReceiver = makeAddr("tokenReceiver");
    }

    function testInitExtended() public {
        bytes32 minterRole = erc20.MINTER_ROLE();
        assertTrue(erc20.hasRole(minterRole, minter));
        bytes32 adminRole = erc20.DEFAULT_ADMIN_ROLE();
        assertTrue(erc20.hasRole(adminRole, admin));
        assertEq(erc20.cap(), supply, "total supply");
        assertTrue(erc20.hasRole(erc20.HUB_OWNER_ROLE(), hubOwner), "hub owner");
    }

    function testMint() public {
        address to = makeAddr("to");
        uint256 amount = 100;
        vm.prank(minter);
        erc20.mint(to, amount);
        assertEq(erc20.balanceOf(to), amount);
    }

    function testOnlyMinterCanMint() public {
        address to = makeAddr("to");
        uint256 amount = 100;
        vm.prank(hubOwner);
        vm.expectRevert("AccessControl: account 0xa268ae5516b47694c3f15805a560258dbcdefd08 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
        erc20.mint(to, amount);
    }

    function testCanOnlyMintUpToMaxSupply() public {
        address to = makeAddr("to");
        uint256 amount = supply;
        vm.startPrank(minter);
        erc20.mint(to, amount);
        assertEq(erc20.balanceOf(to), amount);
        vm.expectRevert("ERC20Capped: cap exceeded");
        erc20.mint(to, 1);
        vm.stopPrank();
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
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        bytes32 hash = erc20.DOMAIN_SEPARATOR();
        hash = keccak256(abi.encodePacked("\x19\x01", hash, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        vm.startPrank(owner);
        erc20.permit(owner, spender, value, deadline, v, r, s);
        vm.stopPrank();

        assertEq(erc20.allowance(owner, spender), value);
    }


}
