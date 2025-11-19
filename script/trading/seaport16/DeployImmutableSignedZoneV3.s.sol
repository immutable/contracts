// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2
pragma solidity 0.8.24;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport16/ImmutableSeaport.sol";
import {ImmutableSignedZoneV3} from "../../../contracts/trading/seaport16/zones/immutable-signed-zone/v3/ImmutableSignedZoneV3.sol";
import {AccessControlledDeployer} from "../../../contracts/deployer/AccessControlledDeployer.sol";
import {IDeployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeployer.sol";

/**
 * @title DeployImmutableSignedZoneV3
 * @notice This script deploys the ImmutableSignedZoneV3 contract via CREATE2.
 * @dev This script assumes that the ImmutableSeaport contract has already been deployed.
 */
contract DeployImmutableSignedZoneV3 is Script {
    address accessControlledDeployerAddress = 0x0B5B1d92259b13D516cCd5a6E63d7D94Ea2A4836;
    address create2DeployerAddress = 0x9df760a54b3B00cC8B3d70A37d45fa97cCfdb4Db;
    address conduitControllerAddress = 0x00000000F9490004C11Cef243f5400493c00Ad63;
    address payable immutableSeaportAddress = payable(0xbE737Cf2C122F83d1610C1224f7B99ca9d0E09f6);
    bytes32 immutableSeaportDeploymentSalt = keccak256(abi.encodePacked("immutable-seaport16"));
    address zoneAddress = 0x18C12fb9c4f6165196c895aDF84230828A85B247;
    bytes32 zoneDeploymentSalt = keccak256(abi.encodePacked("immutable-signed-zone-v3"));
    address seaportInitialOwner = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333; // Immutable Deployer
    address zoneInitialOwner = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333; // Immutable Deployer

    function run() external {
        AccessControlledDeployer deployer = AccessControlledDeployer(accessControlledDeployerAddress);
        IDeployer create2Deployer = IDeployer(create2DeployerAddress);

        // Check supplied immutableSeaportAddress matches the expected address based on current creationCode
        bytes memory immutableSeaportDeploymentBytecode = abi.encodePacked(
            type(ImmutableSeaport).creationCode,
            abi.encode(conduitControllerAddress, seaportInitialOwner)
        );
        address expectedImmutableSeaportAddress = create2Deployer.deployedAddress(immutableSeaportDeploymentBytecode, accessControlledDeployerAddress, immutableSeaportDeploymentSalt);
        console.log("Expected ImmutableSeaport address: %s", expectedImmutableSeaportAddress);
        require(expectedImmutableSeaportAddress == immutableSeaportAddress, "Expected ImmutableSeaport address mismatch");

        // Check supplied zoneAddress matches the expected address based on current creationCode
        bytes memory zoneDeploymentBytecode = abi.encodePacked(
            type(ImmutableSignedZoneV3).creationCode,
            abi.encode("ImmutableSignedZone", immutableSeaportAddress, "", "", zoneInitialOwner)
        );
        address expectedZoneAddress = create2Deployer.deployedAddress(zoneDeploymentBytecode, accessControlledDeployerAddress, zoneDeploymentSalt);
        console.log("Expected ImmutableSignedZoneV3 address: %s", expectedZoneAddress);
        require(expectedZoneAddress == zoneAddress, "Expected ImmutableSignedZoneV3 address mismatch");

        vm.startBroadcast();

        // Deploy zone if it doesn't already exist
        if (zoneAddress.code.length == 0) {
            console.log("Deploying ImmutableSignedZoneV3");
            address deployedZoneAddress = deployer.deploy(create2Deployer, zoneDeploymentBytecode, zoneDeploymentSalt);
            require(deployedZoneAddress == zoneAddress, "Deployed ImmutableSignedZoneV3 address mismatch");
        } else {
            console.log("Skipping ImmutableSignedZoneV3, already exists");
        }

        vm.stopBroadcast();
    }
}

// forge script script/trading/seaport16/DeployImmutableSignedZoneV3.s.sol --rpc-url "https://rpc.testnet.immutable.com" -vvvv --priority-gas-price 10000000000 --with-gas-price 11000000000 --private-key=xx