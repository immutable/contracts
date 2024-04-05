// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ImmutableSignedZoneV2} from "../../../contracts/trading/seaport/zones/ImmutableSignedZoneV2.sol";
import {ConduitController} from "../../../contracts/trading/seaport/conduit/ConduitController.sol";
import {ImmutableSeaportHarness} from "./ImmutableSeaportHarness.sol";
import {ImmutableERC20FixedSupplyNoBurn} from "../../../contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol";
import {ImmutableERC1155} from "../../../contracts/token/erc1155/preset/ImmutableERC1155.sol";
import {OperatorAllowlistUpgradeable} from "../../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {Consideration} from "seaport-core/src/lib/Consideration.sol";
import {
    AdvancedOrder,
    BasicOrderParameters,
    ConsiderationItem,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    OrderComponents,
    OfferItem,
    OrderParameters
} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// solhint-disable func-name-mixedcase

contract ImmutableSeaportSignedZoneV2IntegrationTest is Test {
    ImmutableSeaportHarness seaport;
    ImmutableSignedZoneV2 zone;
    ImmutableERC20FixedSupplyNoBurn erc20Token;
    ImmutableERC1155 erc1155Token;

    address internal immutable OWNER = makeAddr("owner"); // 0x7c8999dC9a822c1f0Df42023113EDB4FDd543266
    address internal immutable SIGNER = makeAddr("signer"); // 0x6E12D8C87503D4287c294f2Fdef96ACd9DFf6bd2
    address internal immutable FULFILLER = makeAddr("fulfiller"); // 0x71458637cD221877830A21F543E8b731e93C3627
    address internal immutable OFFERER = makeAddr("offerer"); // 0xD4A3ED913c988269BbB6caeCBEC568063B43435a
    address internal immutable PROTOCOL_FEE_RECEIVER = makeAddr("ecosystem_fee_receiver");
    address internal immutable ROYALTY_FEE_RECEIVER = makeAddr("royalty_fee_receiver");
    address internal immutable ECOSYSTEM_FEE_RECEIVER = makeAddr("ecosystem_fee_receiver");

    // bytes32 internal immutable ORDER_TYPE_HASH = keccak256(
    //     abi.encodePacked(
    //         abi.encodePacked(
    //             "OrderComponents(",
    //             "address offerer,",
    //             "address zone,",
    //             "OfferItem[] offer,",
    //             "ConsiderationItem[] consideration,",
    //             "uint8 orderType,",
    //             "uint256 startTime,",
    //             "uint256 endTime,",
    //             "bytes32 zoneHash,",
    //             "uint256 salt,",
    //             "bytes32 conduitKey,",
    //             "uint256 counter",
    //             ")"
    //         ),
    //         keccak256(
    //             abi.encodePacked(
    //                 "ConsiderationItem(",
    //                 "uint8 itemType,",
    //                 "address token,",
    //                 "uint256 identifierOrCriteria,",
    //                 "uint256 startAmount,",
    //                 "uint256 endAmount,",
    //                 "address recipient",
    //                 ")"
    //             )
    //         ),
    //         keccak256(
    //             abi.encodePacked(
    //                 "OfferItem(",
    //                 "uint8 itemType,",
    //                 "address token,",
    //                 "uint256 identifierOrCriteria,",
    //                 "uint256 startAmount,",
    //                 "uint256 endAmount",
    //                 ")"
    //             )
    //         )
    //     )
    // );


    function setUp() public {
        // OAL
        OperatorAllowlistUpgradeable operatorAllowlist = new OperatorAllowlistUpgradeable();

        // tokens
        erc20Token = new ImmutableERC20FixedSupplyNoBurn("TestERC20", "ERC20", 1000, OWNER, OWNER);
        erc1155Token = new ImmutableERC1155(
            OWNER,
            "TestERC1155",
            "",
            "",
            address(operatorAllowlist),
            ROYALTY_FEE_RECEIVER,
            100 // 1%
        );

        // seaport
        ConduitController conduitController = new ConduitController();
        seaport = new ImmutableSeaportHarness(address(conduitController), OWNER);
        address[] memory allowlistAddress = new address[](1);
        allowlistAddress[0] = address(seaport);
        operatorAllowlist.addAddressesToAllowlist(allowlistAddress);
        zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            OWNER
        );
        zone.addSigner(SIGNER);
        seaport.setAllowedZone(address(zone), true);
    }

    function test_fulfillAdvancedOrder_withPartialFill() public {
        OfferItem[] memory offerItems = new OfferItem[](1);

        offerItems[0] = OfferItem({
            itemType: ItemType.ERC1155,
            token: address(erc1155Token),
            identifierOrCriteria: uint256(50),
            startAmount: uint256(100),
            endAmount: uint256(100)
        });

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](4);
        // original item
        considerationItems[0] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(200),
            endAmount: uint256(200),
            recipient: OFFERER
        });
        // protocol fee - 2%
        considerationItems[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(4),
            endAmount: uint256(4),
            recipient: PROTOCOL_FEE_RECEIVER
        });
        // royalty fee - 1%
        considerationItems[2] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(2),
            endAmount: uint256(2),
            recipient: ROYALTY_FEE_RECEIVER
        });
        // ecosystem fee - 3%
        considerationItems[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(6),
            endAmount: uint256(6),
            recipient: ECOSYSTEM_FEE_RECEIVER
        });

        OrderParameters orderParameters = OrderParameters({
            offerer: OFFERER,
            zone: address(zone),
            offer: offerItems,
            consideration: considerationItems,
            orderType: OrderType.PARTIAL_RESTRICTED,
            startTime: uint256(1000),
            endTime: uint256(5000),
            zoneHash: bytes32(0),
            salt: uint256(123),
            conduitKey: bytes32(0),
            totalOriginalConsiderationItems: uint256(1)
        });

        bytes32 orderHash = seaport.getOrderHash(
            OrderComponents({
                offerer: orderParameters.offerer,
                zone: orderParameters.zone,
                offer: orderParameters.offer,
                consideration: orderParameters.consideration[0:1],
                orderType: orderParameters.orderType,
                startTime: orderParameters.startTime,
                endTime: orderParameters.endTime,
                zoneHash: orderParameters.zoneHash,
                salt: orderParameters.salt,
                conduitKey: orderParameters.conduitKey,
                counter: seaport.getCounter(orderParameters.offerer)
            })
        );

        bytes32 orderDigest = seaport.exposed_deriveEIP712Digest(seaport.exposed_domainSeparator(), orderHash);

        (, uint256 offererPK) = makeAddrAndKey("offerer");
        (, bytes32 r, bytes32 s) = vm.sign(signerPK, orderDigest);
        bytes memory orderSignature = abi.encodePacked(r, s);

        AdvancedOrder advancedOrder = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(1),
            denominator: uint120(1),
            signature: orderSignature,
            extraData: new bytes(0)
        });

        seaport.fulfillAdvancedOrder(AdvancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);
    }
}

// solhint-enable func-name-mixedcase
