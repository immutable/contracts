// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {GemGame} from "../../../contracts/games/gems/GemGame.sol";

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

struct GemGameContractArgs {
    address defaultAdmin;
    address pauser;
    address unpauser;
}

contract DeployGemGame is Test {
    event GemEarned(address indexed account, uint256 timestamp);

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

        GemGameContractArgs memory gemGameContractArgs = GemGameContractArgs({
            pauser: makeAddr("pause"),
            unpauser: makeAddr("unpause"),
            defaultAdmin: makeAddr("admin")
        });

        // Run deployment against forked testnet
        GemGame deployedGemGameContract = _deploy(deploymentArgs, gemGameContractArgs);

        assertEq(true, deployedGemGameContract.hasRole(keccak256("PAUSE"), gemGameContractArgs.pauser));
        assertEq(true, deployedGemGameContract.hasRole(keccak256("UNPAUSE"), gemGameContractArgs.unpauser));
        assertEq(
            true,
            deployedGemGameContract.hasRole(
                deployedGemGameContract.DEFAULT_ADMIN_ROLE(), gemGameContractArgs.defaultAdmin
            )
        );

        // The DEFAULT_ADMIN_ROLE should be revoked from the deployer account
        assertEq(
            false, deployedGemGameContract.hasRole(deployedGemGameContract.DEFAULT_ADMIN_ROLE(), deploymentArgs.signer)
        );

        // Earn a gem
        vm.expectEmit(true, true, false, false);
        emit GemEarned(address(this), block.timestamp);
        deployedGemGameContract.earnGem();
    }

    function deploy() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address defaultAdmin = vm.envAddress("DEFAULT_ADMIN");
        address pauser = vm.envAddress("PAUSER");
        address unpauser = vm.envAddress("UNPAUSER");
        string memory salt = vm.envString("GEM_GAME_SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({signer: signer, factory: factory, salt: salt});

        GemGameContractArgs memory gemGameContractArgs =
            GemGameContractArgs({defaultAdmin: defaultAdmin, pauser: pauser, unpauser: unpauser});

        _deploy(deploymentArgs, gemGameContractArgs);
    }

    function _deploy(DeploymentArgs memory deploymentArgs, GemGameContractArgs memory gemGameContractArgs)
        internal
        returns (GemGame gemGameContract)
    {
        IDeployer ownableCreate3 = IDeployer(deploymentArgs.factory);

        // Create deployment bytecode and encode constructor args
        bytes memory deploymentBytecode = abi.encodePacked(
            type(GemGame).creationCode,
            abi.encode(gemGameContractArgs.defaultAdmin, gemGameContractArgs.pauser, gemGameContractArgs.unpauser)
        );

        bytes32 saltBytes = keccak256(abi.encode(deploymentArgs.salt));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);

        address gemGameContractAddress = ownableCreate3.deploy(deploymentBytecode, saltBytes);
        gemGameContract = GemGame(gemGameContractAddress);

        vm.stopBroadcast();
    }
}
