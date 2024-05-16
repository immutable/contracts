// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata, ImmutableERC20MinterBurnerPermit, ERC20MinterBurnerPermitCommonTest} from "./ERC20MinterBurnerPermitCommon.t.sol";

/**
 * Test ImmutableERC20MinterBurnerPermit.
 * Most of the tests are inherited.
 * The renounce ownership tests are similar but different to those in HubOwner.t.sol
 * Importantly, the error returned on last owner revocation is different, and hence the tests
 * are different.
 */

contract ImmutableERC20MinterBurnerPermitTest is ERC20MinterBurnerPermitCommonTest {

    function setUp() public virtual override {
        super.setUp();
        erc20 = new ImmutableERC20MinterBurnerPermit(admin, minter, hubOwner, name, symbol, supply);
        basicERC20 = IERC20Metadata(address(erc20));
    }


    function testRenounceAdmin() public {
        address secondAdmin = makeAddr("secondAdmin");
        vm.startPrank(admin);
        erc20.grantRole(erc20.DEFAULT_ADMIN_ROLE(), secondAdmin);
        assertTrue(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), secondAdmin));

        erc20.renounceRole(erc20.DEFAULT_ADMIN_ROLE(), admin);
        assertFalse(erc20.hasRole(erc20.DEFAULT_ADMIN_ROLE(), admin));
        vm.stopPrank();
    }

    function testRenounceLastAdminBlocked() public {
        bytes32 defaultAdminRole = erc20.DEFAULT_ADMIN_ROLE();
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ImmutableERC20MinterBurnerPermit.RenounceOwnershipNotAllowed.selector));
        erc20.renounceRole(defaultAdminRole, admin);
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

    function testRenounceLastHubOwnerBlocked() public {
        bytes32 hubOwnerRole = erc20.HUB_OWNER_ROLE();
        vm.prank(hubOwner);
        vm.expectRevert(abi.encodeWithSelector(ImmutableERC20MinterBurnerPermit.RenounceOwnershipNotAllowed.selector));
        erc20.renounceRole(hubOwnerRole, hubOwner);
    }
}
