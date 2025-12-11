// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {Test} from "forge-std/Test.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {MockOperatorAllowlistUpgradeable} from "./MockOAL.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {DeployOperatorAllowlist} from "../utils/DeployAllowlistProxy.sol";
import {DeploySCWallet} from "../utils/DeploySCW.sol";
import {IWalletProxy} from "../../contracts/allowlist/IWalletProxy.sol";

contract OperatorAllowlistTest is Test, OperatorAllowlistUpgradeable {
    OperatorAllowlistUpgradeable public allowlist;
    ImmutableERC721 public immutableERC721;
    MockOperatorAllowlistUpgradeable public oalV2;
    DeploySCWallet public deploySCWScript;

    uint256 feeReceiverKey = 1;

    address public admin = makeAddr("roleAdmin");
    address public upgrader = makeAddr("roleUpgrader");
    address public registrar = makeAddr("roleRegisterar");
    address public scwOwner = makeAddr("scwOwner");
    address feeReceiver = vm.addr(feeReceiverKey);
    address proxyAddr;
    address nonAuthorizedWallet;
    address scwAddr;
    address scwModuleAddr;

    function setUp() public {
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        proxyAddr = deployScript.run(admin, upgrader, registrar);

        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        immutableERC721 = new ImmutableERC721(
            admin, "test", "USDC", "test-base-uri", "test-contract-uri", address(allowlist), feeReceiver, 0
        );

        nonAuthorizedWallet = address(0x2);

        deploySCWScript = new DeploySCWallet();
    }

    function testDeployment() public view {
        assertTrue(allowlist.hasRole(allowlist.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(allowlist.hasRole(allowlist.REGISTRAR_ROLE(), registrar));
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

    function testUpgradeNoPerms() public {
        MockOperatorAllowlistUpgradeable oalImplV2 = new MockOperatorAllowlistUpgradeable();
        vm.prank(nonAuthorizedWallet);
        vm.expectRevert(abi.encodePacked(
            "AccessControl: account ",
            vm.toString(nonAuthorizedWallet),
            " is missing role 0x555047524144455f524f4c450000000000000000000000000000000000000000"
        ));
        allowlist.upgradeTo(address(oalImplV2));
    }

    function testShouldSupportIOperatorAllowlistInterface() public view {
        assertTrue(allowlist.supportsInterface(0x05a3b809));
    }

    function testShouldLimitAllowlistAddAndRemoveFunctionality() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(0x1);
        vm.startPrank(admin);

        vm.expectRevert(
            "AccessControl: account 0xe48648ee1c7285ff3ad32fa99c427884666caf17 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000"
        );
        allowlist.addAddressesToAllowlist(addressTargets);

        vm.expectRevert(
            "AccessControl: account 0xe48648ee1c7285ff3ad32fa99c427884666caf17 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000"
        );
        allowlist.removeAddressesFromAllowlist(addressTargets);

        vm.expectRevert(
            "AccessControl: account 0xe48648ee1c7285ff3ad32fa99c427884666caf17 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000"
        );
        allowlist.addWalletToAllowlist(address(0x3));

        vm.expectRevert(
            "AccessControl: account 0xe48648ee1c7285ff3ad32fa99c427884666caf17 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000"
        );
        allowlist.removeWalletFromAllowlist(address(0x3));

        vm.stopPrank();
    }

    function testShouldAddAndRemoveSmartContractWalletBytecodeFromAllowlist() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, scwModuleAddr) = deploySCWScript.run(salt);

        IWalletProxy proxy = IWalletProxy(scwAddr);
        address implementationAddress = proxy.PROXY_getImplementation();
        assertEq(implementationAddress, scwModuleAddr);

        bytes memory deployedBytecode = scwAddr.code;

        vm.startPrank(registrar);

        vm.expectEmit(true, true, true, false, address(allowlist));
        emit WalletAllowlistChanged(keccak256(abi.encodePacked(deployedBytecode)), scwAddr, true);
        allowlist.addWalletToAllowlist(scwAddr);
        assertTrue(allowlist.isAllowlisted(scwAddr));

        vm.expectEmit(true, true, true, false, address(allowlist));
        emit WalletAllowlistChanged(keccak256(abi.encodePacked(deployedBytecode)), scwAddr, false);
        allowlist.removeWalletFromAllowlist(scwAddr);
        assertFalse(allowlist.isAllowlisted(scwAddr));

        vm.stopPrank();
    }

    function testShouldAddAndRemoveAnAddressOfAMarketPlaceAndRemoveItFromAllowlist() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(0x1);

        vm.startPrank(registrar);

        vm.expectEmit(true, true, true, false, address(allowlist));
        emit AddressAllowlistChanged(addressTargets[0], true);
        allowlist.addAddressesToAllowlist(addressTargets);
        assertTrue(allowlist.isAllowlisted(addressTargets[0]));

        vm.expectEmit(true, true, true, false, address(allowlist));
        emit AddressAllowlistChanged(addressTargets[0], false);
        allowlist.removeAddressesFromAllowlist(addressTargets);
        assertFalse(allowlist.isAllowlisted(addressTargets[0]));

        vm.stopPrank();
    }

    function testShouldNotAllowlistSCWWithSameBytecodeButDifferentImplementationAddress() public {
        bytes32 salt1 = keccak256(abi.encodePacked("0x5678"));
        address firstScwAddr;
        (firstScwAddr,) = deploySCWScript.run(salt1);

        vm.startPrank(registrar);
        allowlist.addWalletToAllowlist(firstScwAddr);
        assertTrue(allowlist.isAllowlisted(firstScwAddr));

        bytes32 salt2 = keccak256(abi.encodePacked("0x5678"));
        address secondScwAddr;
        (secondScwAddr,) = deploySCWScript.run(salt2);
        assertFalse(allowlist.isAllowlisted(secondScwAddr));
        vm.stopPrank();
    }
}
