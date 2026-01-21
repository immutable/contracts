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

interface IAccessControlledDeployer {
    function deploy(IDeployer deployer, bytes memory bytecode, bytes32 salt) external payable returns (address);
}

struct DeploymentArgs {
    address signer;
    address create3Factory;
    address accessControlledDeployer;
    string salt;
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
            signer: 0xE4D45C0277762CaD4EC40bE69406068DAE74E17d,
            create3Factory: 0xFB1Ecc73c3f3F505d66C055A3571362DE001D9C0,
            accessControlledDeployer: 0x0B5B1d92259b13D516cCd5a6E63d7D94Ea2A4836,
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
        assertEq(false, deployerContract.hasRole(deployerContract.DEFAULT_ADMIN_ROLE(), deploymentArgs.create3Factory));

        // Try to deploy a contract without the deployer role expecting a revert
        vm.prank(makeAddr("notdeployer"));
        vm.expectRevert(Unauthorized.selector);
        deployerContract.deploy("atestname");

        // Deploy a contract with the deployer role
        vm.prank(sessionActivityDeployerArgs.deployer);
        vm.expectEmit(true, false, true, false);
        emit SessionActivityDeployed(sessionActivityDeployerArgs.deployer, address(0), "atestname");
        SessionActivity deployedSessionActivityContract = deployerContract.deploy("atestname");

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
        address create3Factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address accessControlledDeployer = vm.envAddress("ACCESS_CONTROLLED_DEPLOYER_ADDRESS");
        string memory salt = vm.envString("SESSION_ACTIVITY_DEPLOYER_SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({
            signer: signer,
            create3Factory: create3Factory,
            salt: salt,
            accessControlledDeployer: accessControlledDeployer
        });

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
        IAccessControlledDeployer accessControlledDeployer =
            IAccessControlledDeployer(deploymentArgs.accessControlledDeployer);
        IDeployer create3Factory = IDeployer(deploymentArgs.create3Factory);

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

        address sessionActivityDeployerAddress =
            accessControlledDeployer.deploy(create3Factory, deploymentBytecode, saltBytes);
        sessionActivityDeployerContract = SessionActivityDeployer(sessionActivityDeployerAddress);

        vm.stopBroadcast();
    }
}
