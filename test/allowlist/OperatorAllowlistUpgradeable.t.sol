// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {MockOperatorAllowlistUpgradeable} from "./MockOAL.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {DeployOperatorAllowlist} from  "../utils/DeployAllowlistProxy.sol";


contract OperatorAllowlistTest is Test {
    OperatorAllowlistUpgradeable public allowlist;
    ImmutableERC721 public immutableERC721;
    MockOperatorAllowlistUpgradeable public oalV2;

    uint256 feeReceiverKey = 1;

    address public admin = makeAddr("roleAdmin");
    address public upgrader = makeAddr("roleUpgrader");
    address public registerar = makeAddr("roleRegisterar");
    address feeReceiver = vm.addr(feeReceiverKey);
    address proxyAddr;
    address nonAuthorizedWallet;
    

    function setUp() public {
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        proxyAddr = deployScript.run(admin, upgrader, registerar);

        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        immutableERC721 = new ImmutableERC721(
            admin,
            "test",
            "USDC",
            "test-base-uri",
            "test-contract-uri",
            address(allowlist),
            feeReceiver,
            0
        );

        nonAuthorizedWallet = address(0x2);
    }

    function testDeployment() public {
        assertTrue(allowlist.hasRole(allowlist.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(allowlist.hasRole(allowlist.REGISTRAR_ROLE(), registerar));
        assertTrue(allowlist.hasRole(allowlist.UPGRADE_ROLE(), upgrader));
        assertEq(address(immutableERC721.operatorAllowlist()), proxyAddr);
    }

    function testUpgradeToV2() public {
        MockOperatorAllowlistUpgradeable oalImplV2 = new MockOperatorAllowlistUpgradeable();

        vm.prank(upgrader);
        allowlist.upgradeToAndCall(address(oalImplV2), abi.encodeWithSelector(oalImplV2.setMockValue.selector, 50));

        oalV2 = MockOperatorAllowlistUpgradeable(proxyAddr);

        uint256 mockVal = oalV2.mockInt();
        assertEq(mockVal, 50);
    }

    function testFailedUpgradeNoPerms() public {
         MockOperatorAllowlistUpgradeable oalImplV2 = new MockOperatorAllowlistUpgradeable();
        vm.prank(nonAuthorizedWallet);
        vm.expectRevert("Must have upgrade role to upgrade");
        allowlist.upgradeTo(address(oalImplV2));
    }
}