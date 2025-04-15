// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {StakeHolderNative} from "../../contracts/staking/StakeHolderNative.sol";

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
    string salt1;
    string salt2;
}

struct StakeHolderContractArgs {
    address roleAdmin;
    address upgradeAdmin;
    address distributeAdmin;
}

/**
 * @notice Deployment script and test code for the deployment script.
 * @dev testDeploy is the test.
 * @dev deploy() is the function the script should call.
 * For more details on deployment see ../../contracts/staking/README.md
 */
contract DeployStakeHolderNative is Test {
    function testDeploy() external {
        /// @dev Fork the Immutable zkEVM testnet for this test
        string memory rpcURL = "https://rpc.testnet.immutable.com";
        vm.createSelectFork(rpcURL);

        /// @dev These are Immutable zkEVM testnet values where necessary
        DeploymentArgs memory deploymentArgs = DeploymentArgs({
            signer: 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333,
            factory: 0x37a59A845Bb6eD2034098af8738fbFFB9D589610,
            salt1: "salt1",
            salt2: "salt2"
        });

        StakeHolderContractArgs memory stakeHolderContractArgs = StakeHolderContractArgs({
            roleAdmin: makeAddr("role"),
            upgradeAdmin: makeAddr("upgrade"),
            distributeAdmin: makeAddr("distribute")
        });

        // Run deployment against forked testnet
        StakeHolderNative deployedContract = _deploy(deploymentArgs, stakeHolderContractArgs);

        assertTrue(deployedContract.hasRole(deployedContract.UPGRADE_ROLE(), stakeHolderContractArgs.upgradeAdmin), "Upgrade admin should have upgrade role");
        assertTrue(deployedContract.hasRole(deployedContract.DEFAULT_ADMIN_ROLE(), stakeHolderContractArgs.roleAdmin), "Role admin should have default admin role");
        // The DEFAULT_ADMIN_ROLE should be revoked from the deployer account
        assertFalse(deployedContract.hasRole(deployedContract.DEFAULT_ADMIN_ROLE(), deploymentArgs.signer), "msg.sender should not be an admin");
    }

    function deploy() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address roleAdmin = vm.envAddress("ROLE_ADMIN");
        address upgradeAdmin = vm.envAddress("UPGRADE_ADMIN");
        address distributeAdmin = vm.envAddress("DISTRIBUTE_ADMIN");
        string memory salt1 = vm.envString("IMPL_SALT");
        string memory salt2 = vm.envString("PROXY_SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({signer: signer, factory: factory, salt1: salt1, salt2: salt2});

        StakeHolderContractArgs memory stakeHolderContractArgs =
            StakeHolderContractArgs({roleAdmin: roleAdmin, upgradeAdmin: upgradeAdmin, distributeAdmin: distributeAdmin});

        _deploy(deploymentArgs, stakeHolderContractArgs);
    }

    function _deploy(DeploymentArgs memory deploymentArgs, StakeHolderContractArgs memory stakeHolderContractArgs)
        internal
        returns (StakeHolderNative stakeHolderContract)
    {
        IDeployer ownableCreate3 = IDeployer(deploymentArgs.factory);

        // Deploy StakeHolder via the Ownable Create3 factory.
        // That is: StakeHolder impl = new StakeHolder();
        // Create deployment bytecode and encode constructor args
        bytes memory deploymentBytecode = abi.encodePacked(
            type(StakeHolderNative).creationCode
        );
        bytes32 saltBytes = keccak256(abi.encode(deploymentArgs.salt1));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);
        address stakeHolderImplAddress = ownableCreate3.deploy(deploymentBytecode, saltBytes);
        vm.stopBroadcast();

        // Create init data for teh ERC1967 Proxy
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderNative.initialize.selector, stakeHolderContractArgs.roleAdmin, 
            stakeHolderContractArgs.upgradeAdmin, stakeHolderContractArgs.distributeAdmin
        );

        // Deploy ERC1967Proxy via the Ownable Create3 factory.
        // That is: ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        // Create deployment bytecode and encode constructor args
        deploymentBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(stakeHolderImplAddress, initData)
        );
        saltBytes = keccak256(abi.encode(deploymentArgs.salt2));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);
        address stakeHolderContractAddress = ownableCreate3.deploy(deploymentBytecode, saltBytes);
        vm.stopBroadcast();
        stakeHolderContract = StakeHolderNative(stakeHolderContractAddress);
    }
}
