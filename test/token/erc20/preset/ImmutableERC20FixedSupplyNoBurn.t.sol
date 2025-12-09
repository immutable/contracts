// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {Test} from "forge-std/Test.sol";

import {ImmutableERC20FixedSupplyNoBurn} from "contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol";
import {IImmutableERC20Errors} from "contracts/token/erc20/preset/Errors.sol";

contract ImmutableERC20FixedSupplyNoBurnTest is Test {
    ImmutableERC20FixedSupplyNoBurn public erc20;

    address public treasurer;
    address public hubOwner;
    string name;
    string symbol;
    uint256 supply;

    function setUp() public virtual {
        hubOwner = makeAddr("hubOwner");
        treasurer = makeAddr("treasurer");
        name = "HappyToken";
        symbol = "HPY";
        supply = 1000000;

        erc20 = new ImmutableERC20FixedSupplyNoBurn(name, symbol, supply, treasurer, hubOwner);
    }

    function testInit() public {
        assertEq(erc20.name(), name, "name");
        assertEq(erc20.symbol(), symbol, "symbol");
        assertEq(erc20.totalSupply(), supply, "supply");
        assertEq(erc20.balanceOf(treasurer), supply, "initial treasurer balance");
        assertEq(erc20.balanceOf(hubOwner), 0, "initial hub owner balance");
        assertEq(erc20.owner(), hubOwner, "Hub owner");
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
}
