// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDeployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeployer.sol";
import {ERC20MintableBurnable} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnable.sol";
import {ERC20MintableBurnableInit} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnableInit.sol";

import {OwnableCreate2Deployer} from "../../contracts/deployer/create2/OwnableCreate2Deployer.sol";
import {AccessControlledDeployer} from "../../contracts/deployer/AccessControlledDeployer.sol";
import {OwnableCreate3Deployer} from "../../contracts/deployer/create3/OwnableCreate3Deployer.sol";

import {Create2Utils} from "./create2/Create2Utils.sol";
import {Create3Utils} from "./create3/Create3Utils.sol";

contract AccessControlledDeployerTest is Test, Create2Utils, Create3Utils {
    address private admin = makeAddr("admin");
    address private pauser = makeAddr("pauser");
    address private unpauser = makeAddr("unpauser");
    address[] private authDeployers;
    AccessControlledDeployer private rbacDeployer;

    event Deployed(address indexed deployedAddress, address indexed sender, bytes32 indexed salt, bytes32 bytecodeHash);

    error ZeroAddress();
    error EmptyDeployerList();
    error NotOwnerOfDeployer();

    function setUp() public {
        rbacDeployer = new AccessControlledDeployer(admin, pauser, unpauser);

        authDeployers.push(makeAddr("deployer1"));
        vm.prank(admin);
        rbacDeployer.grantDeployerRole(authDeployers);
    }

    /**
     * Constructor
     */
    function test_Constructor_RevertIf_AdminIsZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        new AccessControlledDeployer(address(0), pauser, unpauser);
    }

    function test_Constructor_RevertIf_PauserIsZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        new AccessControlledDeployer(admin, address(0), unpauser);
    }

    function test_Constructor_RevertIf_UnpauserIsZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        new AccessControlledDeployer(admin, pauser, address(0));
    }

    function test_Constructor_AssignsRoles() public {
        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.PAUSER_ROLE(), pauser));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.UNPAUSER_ROLE(), unpauser));
    }

    /**
     * Admin role management
     */
    function test_AdminCanAssignRoles() public {
        address newPauser = makeAddr("newPauser");
        address newUnpauser = makeAddr("newUnpauser");

        assertFalse(rbacDeployer.hasRole(rbacDeployer.PAUSER_ROLE(), newPauser));
        assertFalse(rbacDeployer.hasRole(rbacDeployer.UNPAUSER_ROLE(), newUnpauser));

        vm.startPrank(admin);
        rbacDeployer.grantRole(rbacDeployer.PAUSER_ROLE(), newPauser);
        rbacDeployer.grantRole(rbacDeployer.UNPAUSER_ROLE(), newUnpauser);

        assertTrue(rbacDeployer.hasRole(rbacDeployer.PAUSER_ROLE(), newPauser));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.UNPAUSER_ROLE(), newUnpauser));
    }

    function test_AdminCanRevokeRoles() public {
        vm.startPrank(admin);
        assertTrue(rbacDeployer.hasRole(rbacDeployer.PAUSER_ROLE(), pauser));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.UNPAUSER_ROLE(), unpauser));

        rbacDeployer.revokeRole(rbacDeployer.PAUSER_ROLE(), pauser);
        rbacDeployer.revokeRole(rbacDeployer.UNPAUSER_ROLE(), unpauser);

        assertFalse(rbacDeployer.hasRole(rbacDeployer.PAUSER_ROLE(), pauser));
        assertFalse(rbacDeployer.hasRole(rbacDeployer.UNPAUSER_ROLE(), unpauser));
    }

    function test_RevertIf_TransferDeployerOwnership_ByNonAdmin() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(address(rbacDeployer));
        vm.expectRevert();
        rbacDeployer.transferOwnershipOfDeployer(create2Deployer, makeAddr("newOwner2"));
    }

    function test_RevertIf_TransferDeployerOwnership_WithZeroOwnerAddress() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(address(rbacDeployer));
        vm.startPrank(admin);
        vm.expectRevert(ZeroAddress.selector);
        rbacDeployer.transferOwnershipOfDeployer(create2Deployer, address(0));
    }

    function test_RevertIf_TransferDeployerOwnership_WhenNotCurrentOwner() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(makeAddr("currentOwner"));
        vm.startPrank(admin);
        vm.expectRevert(NotOwnerOfDeployer.selector);
        rbacDeployer.transferOwnershipOfDeployer(create2Deployer, makeAddr("newOwner2"));
    }

    function test_RevertIf_TransferDeployerOwnership_WithZeroDeployerAddress() public {
        vm.startPrank(admin);
        vm.expectRevert(ZeroAddress.selector);
        rbacDeployer.transferOwnershipOfDeployer(Ownable(address(0)), makeAddr("newOwner2"));
    }

    function test_TransferDeployerOwnership_ForOwnableCreate2Deployer() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(address(rbacDeployer));
        assertTrue(create2Deployer.owner() == address(rbacDeployer));

        address newOwner = makeAddr("newOwner");
        vm.startPrank(admin);
        rbacDeployer.transferOwnershipOfDeployer(create2Deployer, newOwner);
        assertTrue(create2Deployer.owner() == newOwner);
    }

    function test_TransferDeployerOwnership_ForOwnableCreate3Deployer() public {
        OwnableCreate3Deployer create3Deployer = new OwnableCreate3Deployer(address(rbacDeployer));
        assertTrue(create2Deployer.owner() == address(rbacDeployer));

        address newOwner = makeAddr("newOwner");
        vm.startPrank(admin);
        rbacDeployer.transferOwnershipOfDeployer(create3Deployer, newOwner);
        assertTrue(create3Deployer.owner() == newOwner);
    }

    /**
     * Pauser and Unpauser role management
     */
    function test_OnlyPauserRoleCanPause() public {
        // check random user can't pause
        vm.expectRevert();
        rbacDeployer.pause();

        // check admin can't pause
        vm.prank(admin);
        vm.expectRevert();
        rbacDeployer.pause();

        // check address with pauser role can pause
        vm.startPrank(pauser);
        rbacDeployer.pause();
        assertTrue(rbacDeployer.paused());
    }

    function test_OnlyUnpauserRoleCanUnpause() public {
        // pause first
        vm.prank(pauser);
        rbacDeployer.pause();
        assertTrue(rbacDeployer.paused());

        // check random address can't unpause
        vm.expectRevert();
        rbacDeployer.pause();

        // check admin can't unpause
        vm.prank(admin);
        vm.expectRevert();
        rbacDeployer.pause();

        // check unpauser role can unpause
        vm.startPrank(unpauser);
        rbacDeployer.unpause();
        assertFalse(rbacDeployer.paused());
    }

    /**
     * Deployer role management
     */
    function test_RevertIf_GrantDeployerRole_WithEmptyArray() public {
        address[] memory emptyDeployers = new address[](0);
        vm.expectRevert(EmptyDeployerList.selector);
        vm.prank(admin);
        rbacDeployer.grantDeployerRole(emptyDeployers);
    }

    function test_RevertIf_GrantDeployerRole_ContainsZeroAddress() public {
        address[] memory newDeployers = new address[](2);
        newDeployers[0] = makeAddr("deployer2");
        // note that second deployer in the array is the zero address

        vm.prank(admin);
        vm.expectRevert(ZeroAddress.selector);
        rbacDeployer.grantDeployerRole(newDeployers);
    }

    function test_GrantDeployerRole_WithOneDeployer() public {
        address[] memory newDeployers = new address[](1);
        newDeployers[0] = makeAddr("deployer2");

        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));

        vm.prank(admin);
        rbacDeployer.grantDeployerRole(newDeployers);

        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));
    }

    function test_GrantDeployerRole_WithMultipleDeployers() public {
        address[] memory newDeployers = new address[](2);
        newDeployers[0] = makeAddr("deployer2");
        newDeployers[1] = makeAddr("deployer3");

        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));
        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[1]));

        vm.prank(admin);
        rbacDeployer.grantDeployerRole(newDeployers);

        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[1]));
    }

    function test_RevertIf_RevokeDeployerRole_WithEmptyArray() public {
        address[] memory emptyDeployers = new address[](0);
        vm.expectRevert(EmptyDeployerList.selector);
        vm.prank(admin);
        rbacDeployer.revokeDeployerRole(emptyDeployers);
    }

    function test_RevertIf_RevokeDeployerRole_ContainsZeroAddress() public {
        address[] memory existingDeployers = new address[](2);
        existingDeployers[0] = makeAddr("deployer1");
        // note that second deployer in the array is the zero address

        vm.prank(admin);
        vm.expectRevert(ZeroAddress.selector);
        rbacDeployer.grantDeployerRole(existingDeployers);
    }

    function test_RevokeDeployerRole_GivenOneDeployer() public {
        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), authDeployers[0]));

        vm.prank(admin);
        rbacDeployer.revokeDeployerRole(authDeployers);

        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), authDeployers[0]));
    }

    function test_RevokeDeployerRole_GivenMultipleDeployers() public {
        address[] memory newDeployers = new address[](2);
        newDeployers[0] = makeAddr("deployer2");
        newDeployers[1] = makeAddr("deployer3");

        vm.prank(admin);
        rbacDeployer.grantDeployerRole(newDeployers);

        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));
        assertTrue(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[1]));

        vm.prank(admin);
        rbacDeployer.revokeDeployerRole(newDeployers);

        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[0]));
        assertFalse(rbacDeployer.hasRole(rbacDeployer.DEPLOYER_ROLE(), newDeployers[1]));
    }

    /**
     * Contract Deployment
     */
    function test_RevertIf_Deploy_WithUnauthorizedAddress() public {
        vm.expectRevert();
        rbacDeployer.deploy(IDeployer(address(0)), new bytes(0), bytes32(0));
    }

    function test_Deploy_UsingCreate2() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(address(rbacDeployer));
        bytes memory erc20MintableBytecode =
            abi.encodePacked(type(ERC20MintableBurnable).creationCode, abi.encode("Test Token", "TEST", 10));
        bytes32 erc20MintableSalt = createSaltFromKey("erc20-mintable-burnable-v1", address(rbacDeployer));

        address expectedAddress = predictCreate2Address(
            erc20MintableBytecode, address(create2Deployer), address(rbacDeployer), erc20MintableSalt
        );

        vm.startPrank(authDeployers[0]);
        vm.expectEmit();
        emit Deployed(expectedAddress, address(rbacDeployer), erc20MintableSalt, keccak256(erc20MintableBytecode));
        address deployedAddress = rbacDeployer.deploy(create2Deployer, erc20MintableBytecode, erc20MintableSalt);
        ERC20MintableBurnable deployed = ERC20MintableBurnable(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
        assertEq(deployed.decimals(), 10, "deployed contract does not match expected");
    }

    function test_DeployAndInit_UsingCreate2() public {
        OwnableCreate2Deployer create2Deployer = new OwnableCreate2Deployer(address(rbacDeployer));
        bytes memory mintableInitBytecode =
            abi.encodePacked(type(ERC20MintableBurnableInit).creationCode, abi.encode(10));

        bytes32 mintableInitSalt = createSaltFromKey("erc20-mintable-burnable-init-v1", address(rbacDeployer));

        address expectedAddress = predictCreate2Address(
            mintableInitBytecode, address(create2Deployer), address(rbacDeployer), mintableInitSalt
        );

        bytes memory initPayload = abi.encodeWithSelector(ERC20MintableBurnableInit.init.selector, "Test Token", "TEST");
        vm.startPrank(authDeployers[0]);
        vm.expectEmit();
        emit Deployed(expectedAddress, address(rbacDeployer), mintableInitSalt, keccak256(mintableInitBytecode));
        address deployedAddress =
            rbacDeployer.deployAndInit(create2Deployer, mintableInitBytecode, mintableInitSalt, initPayload);
        ERC20MintableBurnableInit deployed = ERC20MintableBurnableInit(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
        assertEq(deployed.decimals(), 10, "deployed contract does not match expected");
    }

    function test_Deploy_UsingCreate3() public {
        OwnableCreate3Deployer create3Deployer = new OwnableCreate3Deployer(address(rbacDeployer));
        bytes memory erc20MintableBytecode =
            abi.encodePacked(type(ERC20MintableBurnable).creationCode, abi.encode("Test Token", "TEST", 10));
        bytes32 erc20MintableSalt = createSaltFromKey("erc20-mintable-burnable-v1", address(rbacDeployer));

        address expectedAddress = predictCreate3Address(create3Deployer, address(rbacDeployer), erc20MintableSalt);

        vm.startPrank(authDeployers[0]);
        vm.expectEmit();
        emit Deployed(expectedAddress, address(rbacDeployer), erc20MintableSalt, keccak256(erc20MintableBytecode));
        address deployedAddress = rbacDeployer.deploy(create3Deployer, erc20MintableBytecode, erc20MintableSalt);
        ERC20MintableBurnable deployed = ERC20MintableBurnable(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
        assertEq(deployed.decimals(), 10, "deployed contract does not match expected");
    }

    function test_DeployAndInit_UsingCreate3() public {
        OwnableCreate3Deployer create3Deployer = new OwnableCreate3Deployer(address(rbacDeployer));
        bytes memory erc20MintableInitBytcode =
            abi.encodePacked(type(ERC20MintableBurnableInit).creationCode, abi.encode(10));

        bytes32 erc20MintableSalt = createSaltFromKey("erc20-mintable-burnable-init-v1", address(rbacDeployer));

        address expectedAddress = predictCreate3Address(create3Deployer, address(rbacDeployer), erc20MintableSalt);

        vm.startPrank(authDeployers[0]);
        bytes memory initPayload = abi.encodeWithSelector(ERC20MintableBurnableInit.init.selector, "Test Token", "TEST");
        vm.expectEmit();
        emit Deployed(expectedAddress, address(rbacDeployer), erc20MintableSalt, keccak256(erc20MintableInitBytcode));
        address deployedAddress =
            rbacDeployer.deployAndInit(create3Deployer, erc20MintableInitBytcode, erc20MintableSalt, initPayload);
        ERC20MintableBurnableInit deployed = ERC20MintableBurnableInit(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
        assertEq(deployed.decimals(), 10, "deployed contract does not match expected");
    }

    function test_DeployFails_WhenPaused() public {
        vm.startPrank(pauser);

        rbacDeployer.pause();
        assertTrue(rbacDeployer.paused());

        vm.expectRevert("Pausable: paused");
        rbacDeployer.deploy(IDeployer(address(0)), new bytes(0), bytes32(0));

        vm.expectRevert("Pausable: paused");
        rbacDeployer.deployAndInit(IDeployer(address(0)), new bytes(0), bytes32(0), new bytes(0));
    }
}
