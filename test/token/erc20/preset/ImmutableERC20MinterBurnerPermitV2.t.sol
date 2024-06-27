// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata, ImmutableERC20MinterBurnerPermit, ERC20MinterBurnerPermitCommonTest} from "./ERC20MinterBurnerPermitCommon.t.sol";
import {ImmutableERC20MinterBurnerPermitV2} from "contracts/token/erc20/preset/ImmutableERC20MinterBurnerPermitV2.sol";

contract ImmutableERC20MinterBurnerPermitV2Test is ERC20MinterBurnerPermitCommonTest {
    ImmutableERC20MinterBurnerPermitV2 public erc20V2;

    function setUp() public virtual override {
        super.setUp();
        erc20V2 = new ImmutableERC20MinterBurnerPermitV2(admin, minter, hubOwner, name, symbol, supply);
        erc20 = ImmutableERC20MinterBurnerPermit(address(erc20V2));
        basicERC20 = IERC20Metadata(address(erc20V2));
    }

    function testCheckOwner() public {
        assertEq(erc20V2.owner(), hubOwner, "Hub owner");
    }
}
