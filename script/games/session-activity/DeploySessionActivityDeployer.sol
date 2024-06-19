// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {SessionActivity} from "../../../contracts/games/session-activity/SessionActivity.sol";
import {
    SessionActivityDeployer,
    Unauthorized
} from "../../../contracts/games/session-activity/SessionActivityDeployer.sol";

/**
 * @title IDeployer Interface
 * @notice This interface defines the contract responsible for deploying and optionally initializing new contracts
 *  via a specified deployment method.
 * @dev Credit to axelarnetwork https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/main/contracts/interfaces/IDeployer.sol
 */
interface IDeployer {
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address deployedAddress_);
    function deployAndInit(bytes memory bytecode, bytes32 salt, bytes calldata init)
        external
        payable
        returns (address deployedAddress_);
    function deployedAddress(bytes calldata bytecode, address sender, bytes32 salt)
        external
        view
        returns (address deployedAddress_);
}

struct DeploymentArgs {
    address signer;
    address factory;
    string salt;
}

struct SessionActivityContractArgs {
    address defaultAdmin;
    address pauser;
    address unpauser;
    string name;
}

struct SessionActivityDeployerArgs {
    address admin;
    address deployer;
    address pauser;
    address unpauser;
}

contract DeploySessionActivityDeployer is Test {
    event SessionActivityRecorded(address indexed account, uint256 timestamp);
    event SessionActivityDeployed(address indexed account, address indexed deployedContract, string indexed name);

    function testDeploy() external {
        /// @dev Fork the Immutable zkEVM testnet for this test
        string memory rpcURL = "https://rpc.testnet.immutable.com";
        vm.createSelectFork(rpcURL);

        /// @dev These are Immutable zkEVM testnet values where necessary
        DeploymentArgs memory deploymentArgs = DeploymentArgs({
            signer: 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333,
            factory: 0x37a59A845Bb6eD2034098af8738fbFFB9D589610,
            salt: "salty"
        });

        SessionActivityDeployerArgs memory sessionActivityDeployerArgs = SessionActivityDeployerArgs({
            pauser: makeAddr("pause"),
            unpauser: makeAddr("unpause"),
            admin: makeAddr("admin"),
            deployer: makeAddr("deployer")
        });

        // Run deployment against forked testnet
        SessionActivityDeployer deployerContract = _deploy(deploymentArgs, sessionActivityDeployerArgs);

        // Assert roles are assigned correctly
        assertEq(true, deployerContract.hasRole(keccak256("DEPLOYER"), sessionActivityDeployerArgs.deployer));
        assertEq(
            true, deployerContract.hasRole(deployerContract.DEFAULT_ADMIN_ROLE(), sessionActivityDeployerArgs.admin)
        );

        // The DEFAULT_ADMIN_ROLE should be revoked from the deployer account and the factory contract address
        assertEq(false, deployerContract.hasRole(deployerContract.DEFAULT_ADMIN_ROLE(), deploymentArgs.signer));
        assertEq(false, deployerContract.hasRole(deployerContract.DEFAULT_ADMIN_ROLE(), deploymentArgs.factory));

        // Try to deploy a contract without the deployer role expecting a revert
        vm.prank(makeAddr("notdeployer"));
        vm.expectRevert(Unauthorized.selector);
        deployerContract.deploy("SessionActivity");

        // Deploy a contract with the deployer role
        vm.prank(sessionActivityDeployerArgs.deployer);
        vm.expectEmit(true, false, true, false);
        emit SessionActivityDeployed(sessionActivityDeployerArgs.deployer, address(0), "MyCoolGame");
        SessionActivity deployedSessionActivityContract = deployerContract.deploy("MyCoolGame");

        // Asset roles are assigned correctly on the child contract
        assertEq(true, deployedSessionActivityContract.hasRole(keccak256("PAUSE"), sessionActivityDeployerArgs.pauser));
        assertEq(
            true, deployedSessionActivityContract.hasRole(keccak256("UNPAUSE"), sessionActivityDeployerArgs.unpauser)
        );
        assertEq(
            true,
            deployedSessionActivityContract.hasRole(
                deployedSessionActivityContract.DEFAULT_ADMIN_ROLE(), sessionActivityDeployerArgs.admin
            )
        );

        // Record a session activity
        vm.expectEmit(true, true, true, false);
        emit SessionActivityRecorded(address(this), block.timestamp);
        deployedSessionActivityContract.recordSessionActivity();
    }

    function deploy() external {
        address signer = vm.envAddress("SIGNER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        string memory salt = vm.envString("SESSION_ACTIVITY_DEPLOYER_SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({signer: signer, factory: factory, salt: salt});

        address defaultAdmin = vm.envAddress("DEFAULT_ADMIN");
        address deployer = vm.envAddress("DEPLOYER");
        address pauser = vm.envAddress("PAUSER");
        address unpauser = vm.envAddress("UNPAUSER");

        SessionActivityDeployerArgs memory sessionActivityDeployerArgs =
            SessionActivityDeployerArgs({admin: defaultAdmin, deployer: deployer, pauser: pauser, unpauser: unpauser});

        _deploy(deploymentArgs, sessionActivityDeployerArgs);
    }

    function _deploy(
        DeploymentArgs memory deploymentArgs,
        SessionActivityDeployerArgs memory sessionActivityDeployerArgs
    ) internal returns (SessionActivityDeployer sessionActivityDeployerContract) {
        IDeployer ownableCreate3 = IDeployer(deploymentArgs.factory);

        // Create deployment bytecode and encode constructor args
        bytes memory deploymentBytecode = abi.encodePacked(
            type(SessionActivityDeployer).creationCode,
            abi.encode(
                sessionActivityDeployerArgs.admin,
                sessionActivityDeployerArgs.deployer,
                sessionActivityDeployerArgs.pauser,
                sessionActivityDeployerArgs.unpauser
            )
        );

        bytes32 saltBytes = keccak256(abi.encode(deploymentArgs.salt));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);

        address sessionActivityDeployerAddress = ownableCreate3.deploy(deploymentBytecode, saltBytes);
        sessionActivityDeployerContract = SessionActivityDeployer(sessionActivityDeployerAddress);

        vm.stopBroadcast();
    }
}
