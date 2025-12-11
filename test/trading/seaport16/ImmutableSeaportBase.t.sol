// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport16/ImmutableSeaport.sol";
import {ImmutableSignedZoneV3} from "../../../contracts/trading/seaport16/zones/immutable-signed-zone/v3/ImmutableSignedZoneV3.sol";
import {ConduitController} from "seaport-core-16/src/conduit/ConduitController.sol";
import {Conduit} from "seaport-core-16/src/conduit/Conduit.sol";


abstract contract ImmutableSeaportBaseTest is Test {
    event AllowedZoneSet(address zoneAddress, bool allowed);

    ImmutableSeaport public immutableSeaport;
    ImmutableSignedZoneV3 public immutableSignedZone;
    ConduitController public conduitController;
    Conduit public conduit;
    bytes32 public conduitKey;
    address public conduitAddress;
    address public owner;
    address public zoneManager;
    address public immutableSigner;
    uint256 public immutableSignerPkey;
    address public buyer;
    address public seller;
    uint256 public buyerPkey;
    uint256 public sellerPkey;

    function setUp() public virtual {
        // Set up chain ID
        //uint256 chainId = block.chainid;

        // Create test addresses
        owner = makeAddr("owner");
        zoneManager = makeAddr("zoneManager");
        (immutableSigner, immutableSignerPkey) = makeAddrAndKey("immutableSigner");
        (buyer, buyerPkey) = makeAddrAndKey("buyer");
        (seller, sellerPkey) = makeAddrAndKey("seller");

        // Deploy contracts

        // The conduit key used to deploy the conduit. Note that the first twenty bytes of the conduit key must match the caller of this contract.
        conduitKey = bytes32(uint256(uint160(owner)) << (256-160));
        conduitController = new ConduitController();
        vm.prank(owner);
        conduitController.createConduit(conduitKey, owner);
        bool exists;
        (conduitAddress, exists) = conduitController.getConduit(conduitKey);
        assertTrue(exists, "Condiut contract does not exist");
        conduit = Conduit(conduitAddress);

        immutableSeaport = new ImmutableSeaport(address(conduitController), owner);

        immutableSignedZone = new ImmutableSignedZoneV3("ImmutableSignedZone", address(immutableSeaport), "", "", owner);
        bytes32 zoneManagerRole = immutableSignedZone.ZONE_MANAGER_ROLE();
        vm.prank(owner);
        immutableSignedZone.grantRole(zoneManagerRole, zoneManager);
        vm.prank(zoneManager);
        immutableSignedZone.addSigner(immutableSigner);

        vm.prank(owner);
        immutableSeaport.setAllowedZone(address(immutableSignedZone), true);
        vm.prank(owner);
        conduitController.updateChannel(conduitAddress, address(immutableSeaport), true);
    }
}