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
    address private constant ACCESS_CONTROLLED_DEPLOYER_ADDRESS = 0x0B5B1d92259b13D516cCd5a6E63d7D94Ea2A4836;
    address private constant CREATE2_DEPLOYER_ADDRESS = 0x9df760a54b3B00cC8B3d70A37d45fa97cCfdb4Db;
    address private constant CONDUIT_CONTROLLER_ADDRESS = 0x00000000F9490004C11Cef243f5400493c00Ad63;
    address private constant IMMUTABLE_SEAPORT_ADDRESS = 0xbE737Cf2C122F83d1610C1224f7B99ca9d0E09f6;
    bytes32 private constant IMMUTABLE_SEAPORT_DEPLOYMENT_SALT = keccak256(abi.encodePacked("immutable-seaport16"));
    address private constant ZONE_ADDRESS = 0x18C12fb9c4f6165196c895aDF84230828A85B247;
    bytes32 private constant ZONE_DEPLOYMENT_SALT = keccak256(abi.encodePacked("immutable-signed-zone-v3"));
    address private constant SEAPORT_INITIAL_OWNER = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333; // Immutable Deployer
    address private constant ZONE_INITIAL_OWNER = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333; // Immutable Deployer

    function run() external {
        AccessControlledDeployer deployer = AccessControlledDeployer(ACCESS_CONTROLLED_DEPLOYER_ADDRESS);
        IDeployer create2Deployer = IDeployer(CREATE2_DEPLOYER_ADDRESS);

        // Check supplied IMMUTABLE_SEAPORT_ADDRESS matches the expected address based on current creationCode
        bytes memory immutableSeaportDeploymentBytecode = abi.encodePacked(
            type(ImmutableSeaport).creationCode,
            abi.encode(CONDUIT_CONTROLLER_ADDRESS, SEAPORT_INITIAL_OWNER)
        );
        address expectedIMMUTABLE_SEAPORT_ADDRESS = create2Deployer.deployedAddress(immutableSeaportDeploymentBytecode, ACCESS_CONTROLLED_DEPLOYER_ADDRESS, IMMUTABLE_SEAPORT_DEPLOYMENT_SALT);
        console.log("Expected ImmutableSeaport address: %s", expectedIMMUTABLE_SEAPORT_ADDRESS);
        require(expectedIMMUTABLE_SEAPORT_ADDRESS == IMMUTABLE_SEAPORT_ADDRESS, "Expected ImmutableSeaport address mismatch");

        // Check supplied ZONE_ADDRESS matches the expected address based on current creationCode
        bytes memory zoneDeploymentBytecode = abi.encodePacked(
            type(ImmutableSignedZoneV3).creationCode,
            abi.encode("ImmutableSignedZone", IMMUTABLE_SEAPORT_ADDRESS, "", "", ZONE_INITIAL_OWNER)
        );
        address expectedZoneAddress = create2Deployer.deployedAddress(zoneDeploymentBytecode, ACCESS_CONTROLLED_DEPLOYER_ADDRESS, ZONE_DEPLOYMENT_SALT);
        console.log("Expected ImmutableSignedZoneV3 address: %s", expectedZoneAddress);
        require(expectedZoneAddress == ZONE_ADDRESS, "Expected ImmutableSignedZoneV3 address mismatch");

        vm.startBroadcast();

        // Deploy zone if it doesn't already exist
        if (ZONE_ADDRESS.code.length == 0) {
            console.log("Deploying ImmutableSignedZoneV3");
            address deployedZoneAddress = deployer.deploy(create2Deployer, zoneDeploymentBytecode, ZONE_DEPLOYMENT_SALT);
            require(deployedZoneAddress == ZONE_ADDRESS, "Deployed ImmutableSignedZoneV3 address mismatch");
        } else {
            console.log("Skipping ImmutableSignedZoneV3, already exists");
        }

        vm.stopBroadcast();
    }
}

// forge script script/trading/seaport16/DeployImmutableSignedZoneV3.s.sol --rpc-url "https://rpc.testnet.immutable.com" -vvvv --priority-gas-price 10000000000 --with-gas-price 11000000000 --private-key=xx
