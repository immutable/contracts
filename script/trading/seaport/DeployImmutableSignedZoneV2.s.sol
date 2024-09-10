// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2
// solhint-disable-next-line compiler-version
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ImmutableSignedZoneV2} from
    "../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/ImmutableSignedZoneV2.sol";

/**
 * @title IDeployer Interface
 * @notice This interface defines the contract responsible for deploying and optionally initializing new contracts
 *  via a specified deployment method.
 * @dev Credit to axelarnetwork https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/main/contracts/interfaces/IDeployer.sol
 */
interface IDeployer {
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address deployedAddress_);
}

struct DeploymentArgs {
    address signer;
    address factory;
    string salt;
}

struct ZoneDeploymentArgs {
    address owner;
    string name;
    string apiEndpoint;
    string documentationURI;
}

contract DeployImmutableSignedZoneV2 is Test {
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

        /// @dev These are Immutable zkEVM testnet values where necessary
        ZoneDeploymentArgs memory zoneDeploymentArgs = ZoneDeploymentArgs({
            owner: address(0xC606830D8341bc9F5F5Dd7615E9313d2655B505D),
            name: "TestImmutableSignedZoneV2",
            apiEndpoint: "https://api.sandbox.immutable.com/",
            documentationURI: ""
        });

        // Run deployment against forked testnet
        ImmutableSignedZoneV2 deployedContract = _deploy(deploymentArgs, zoneDeploymentArgs);

        // Assert
        (, string memory apiEndpoint,, string memory documentationURI) = deployedContract.sip7Information();

        assertEq(
            true,
            (keccak256(abi.encodePacked(apiEndpoint)) == keccak256(abi.encodePacked(zoneDeploymentArgs.apiEndpoint)))
        );
        assertEq(
            true,
            (
                keccak256(abi.encodePacked(documentationURI))
                    == keccak256(abi.encodePacked(zoneDeploymentArgs.documentationURI))
            )
        );
    }

    function deploy() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address owner = vm.envAddress("OWNER");
        string memory documentationURI = vm.envString("DOCUMENTATION_URI");
        string memory apiEndpoint = vm.envString("API_ENDPOINT");
        string memory name = vm.envString("NAME");
        string memory salt = vm.envString("SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({signer: signer, factory: factory, salt: salt});

        ZoneDeploymentArgs memory zoneDeploymentArgs =
            ZoneDeploymentArgs({owner: owner, apiEndpoint: apiEndpoint, documentationURI: documentationURI, name: name});

        _deploy(deploymentArgs, zoneDeploymentArgs);
    }

    function _deploy(DeploymentArgs memory deploymentArgs, ZoneDeploymentArgs memory zoneArgs)
        internal
        returns (ImmutableSignedZoneV2 zoneContract)
    {
        IDeployer ownableCreate3 = IDeployer(deploymentArgs.factory);

        // Create deployment bytecode and encode constructor args
        bytes memory deploymentBytecode = abi.encodePacked(
            type(ImmutableSignedZoneV2).creationCode,
            abi.encode(zoneArgs.name, zoneArgs.apiEndpoint, zoneArgs.documentationURI, zoneArgs.owner)
        );

        bytes32 saltBytes = keccak256(abi.encode(deploymentArgs.salt));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);

        address deployedAddress = ownableCreate3.deploy(deploymentBytecode, saltBytes);
        zoneContract = ImmutableSignedZoneV2(deployedAddress);

        vm.stopBroadcast();
    }
}
