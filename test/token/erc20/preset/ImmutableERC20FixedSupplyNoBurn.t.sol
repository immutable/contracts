// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata, ERC20TestCommon} from "./ERC20TestCommon.t.sol";
import {ImmutableERC20FixedSupplyNoBurn} from "contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol";

contract ImmutableERC20FixedSupplyNoBurnTest is ERC20TestCommon {
    ImmutableERC20FixedSupplyNoBurn public erc20;

    function setUp() public virtual override {
        super.setUp();
        erc20 = new ImmutableERC20FixedSupplyNoBurn(name, symbol, supply, treasurer, hubOwner);
        basicERC20 = IERC20Metadata(address(erc20));
    }

    function testInitExtended() public {
        assertEq(basicERC20.totalSupply(), supply, "supply");
        assertEq(basicERC20.balanceOf(treasurer), supply, "initial treasurer balance");
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
        vm.expectRevert(abi.encodeWithSelector(ImmutableERC20FixedSupplyNoBurn.RenounceOwnershipNotAllowed.selector));
        erc20.renounceOwnership();
    }    
}
