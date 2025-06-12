// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport/ImmutableSeaport.sol";
import {ImmutableSignedZone} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";

import {ConduitController} from "seaport-core/src/conduit/ConduitController.sol";
import {Conduit} from "seaport-core/src/conduit/Conduit.sol";
import {Consideration} from "seaport-core/src/lib/Consideration.sol";
import {OrderParameters, OrderComponents, Order, AdvancedOrder, FulfillmentComponent, FulfillmentComponent, CriteriaResolver} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ReceivedItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";






abstract contract ImmutableSeaportBaseTest is Test {
    event AllowedZoneSet(address zoneAddress, bool allowed);

    ImmutableSeaport public immutableSeaport;
    ImmutableSignedZone public immutableSignedZone;
    ConduitController public conduitController;
    Conduit public conduit;
    bytes32 public conduitKey;
    address public conduitAddress;
    address public owner;
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
        (immutableSigner, immutableSignerPkey) = makeAddrAndKey("immutableSigner");
        (buyer, buyerPkey) = makeAddrAndKey("buyer");
        (seller, sellerPkey) = makeAddrAndKey("seller");

        // Deploy contracts
        immutableSignedZone = new ImmutableSignedZone("ImmutableSignedZone", "", "", owner);
        vm.prank(owner);
        immutableSignedZone.addSigner(immutableSigner);

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

        vm.prank(owner);
        immutableSeaport.setAllowedZone(address(immutableSignedZone), true);
        vm.prank(owner);
        conduitController.updateChannel(conduitAddress, address(immutableSeaport), true);
    }
}