// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {HubOwner} from "contracts/token/common/HubOwner.sol";


// Contract that isn't abstract, and hence allows the contract to be instantiated
contract HubOwnerImpl is HubOwner {
    constructor(address _roleAdmin, address _hubOwner) HubOwner(_roleAdmin, _hubOwner) {
    }
}

contract HubOwnerTest is Test {
    HubOwner public tokenContract;

    address public hubOwner;
    address public admin;

    function setUp() public virtual {
        admin = makeAddr("admin");
        hubOwner = makeAddr("hubOwner");

        tokenContract = new HubOwnerImpl(admin, hubOwner);
    }

    function testInit() public {
        assertTrue(tokenContract.hasRole(tokenContract.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(tokenContract.getRoleMemberCount(tokenContract.DEFAULT_ADMIN_ROLE()), 1, "one admin");
        assertTrue(tokenContract.hasRole(tokenContract.HUB_OWNER_ROLE(), hubOwner), "hub owner");
        assertEq(tokenContract.getRoleMemberCount(tokenContract.HUB_OWNER_ROLE()), 1, "one hub owner");
    }

    function testRenounceAdmin() public {
        address secondAdmin = makeAddr("secondAdmin");
        vm.startPrank(admin);
        tokenContract.grantRole(tokenContract.DEFAULT_ADMIN_ROLE(), secondAdmin);
        assertTrue(tokenContract.hasRole(tokenContract.DEFAULT_ADMIN_ROLE(), secondAdmin));

        tokenContract.renounceRole(tokenContract.DEFAULT_ADMIN_ROLE(), admin);
        assertFalse(tokenContract.hasRole(tokenContract.DEFAULT_ADMIN_ROLE(), admin));
        vm.stopPrank();
    }

    function testRenounceLastAdminBlocked() public {
        bytes32 defaultAdminRole = tokenContract.DEFAULT_ADMIN_ROLE();
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(HubOwner.RenounceLastNotAllowed.selector));
        tokenContract.renounceRole(defaultAdminRole, admin);
    }

    function testRenounceHubOwner() public {
        address secondHubOwner = makeAddr("secondHubOwner");
        vm.startPrank(admin);
        tokenContract.grantRole(tokenContract.HUB_OWNER_ROLE(), secondHubOwner);
        assertTrue(tokenContract.hasRole(tokenContract.HUB_OWNER_ROLE(), secondHubOwner));
        vm.stopPrank();

        vm.startPrank(hubOwner);
        tokenContract.renounceRole(tokenContract.HUB_OWNER_ROLE(), hubOwner);
        assertFalse(tokenContract.hasRole(tokenContract.HUB_OWNER_ROLE(), hubOwner));
        vm.stopPrank();
    }

    function testRenounceLastHubOwnerBlocked() public {
        bytes32 hubOwnerRole = tokenContract.HUB_OWNER_ROLE();
        vm.prank(hubOwner);
        vm.expectRevert(abi.encodeWithSelector(HubOwner.RenounceLastNotAllowed.selector));
        tokenContract.renounceRole(hubOwnerRole, hubOwner);
    }
}
