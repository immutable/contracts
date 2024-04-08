// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {ImmutableSignedZoneV2Harness} from "./zones/ImmutableSignedZoneV2Harness.t.sol";
import {ConduitController} from "../../../contracts/trading/seaport/conduit/ConduitController.sol";
import {ImmutableSeaportHarness} from "./ImmutableSeaportHarness.t.sol";
import {ImmutableERC20FixedSupplyNoBurn} from
    "../../../contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol";
import {ImmutableERC1155} from "../../../contracts/token/erc1155/preset/ImmutableERC1155.sol";
import {OperatorAllowlistUpgradeable} from "../../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    OrderComponents,
    OfferItem,
    OrderParameters
} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// solhint-disable func-name-mixedcase, private-vars-leading-underscore

contract ImmutableSeaportSignedZoneV2IntegrationTest is Test {
    ImmutableSeaportHarness internal seaport;
    ImmutableSignedZoneV2Harness internal zone;
    ImmutableERC20FixedSupplyNoBurn internal erc20Token;
    ImmutableERC1155 internal erc1155Token;

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
        // operator allowlist
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
        vm.prank(OWNER);
        erc1155Token.grantMinterRole(OWNER);

        // zone
        zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            OWNER
        );
        zone.addSigner(SIGNER);

        // seaport
        ConduitController conduitController = new ConduitController();
        seaport = new ImmutableSeaportHarness(address(conduitController), OWNER);
        seaport.setAllowedZone(address(zone), true);

        // operator allowlist addresses
        address[] memory allowlistAddress = new address[](1);
        allowlistAddress[0] = address(seaport);
        operatorAllowlist.addAddressesToAllowlist(allowlistAddress);
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
            startTime: uint256(0),
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
        (, bytes32 listingR, bytes32 listingS) = vm.sign(signerPK, orderDigest);
        bytes memory orderSignature = abi.encodePacked(listingR, listingS);

        (, uint256 signerPK) = makeAddrAndKey("signer");
        ReceivedItem[] memory expectedReceivedItems = new ReceivedItem[](4);
        receivedItems[0] = ReceivedItem({
            itemType: considerationItems[0].itemType,
            token: considerationItems[0].token,
            identifier: considerationItems[0].identifierOrCriteria,
            amount: considerationItems[0].startAmount,
            recipient: considerationItems[0].recipient
        });
        receivedItems[1] = ReceivedItem({
            itemType: considerationItems[1].itemType,
            token: considerationItems[1].token,
            identifier: considerationItems[1].identifierOrCriteria,
            amount: considerationItems[1].startAmount,
            recipient: considerationItems[1].recipient
        });
        receivedItems[2] = ReceivedItem({
            itemType: considerationItems[2].itemType,
            token: considerationItems[2].token,
            identifier: considerationItems[2].identifierOrCriteria,
            amount: considerationItems[2].startAmount,
            recipient: considerationItems[2].recipient
        });
        receivedItems[3] = ReceivedItem({
            itemType: considerationItems[3].itemType,
            token: considerationItems[3].token,
            identifier: considerationItems[3].identifierOrCriteria,
            amount: considerationItems[3].startAmount,
            recipient: considerationItems[3].recipient
        });
        bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
        bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
        bytes32 eip712SignedOrderHash = zone.exposed_deriveSignedOrderHash(FULFILLER, uint256(4000), orderHash, context);
        bytes32 signatureDigest = ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash);
        (, bytes32 signedOrderR, bytes32 signedOrderS) = vm.sign(signerPK, signatureDigest);
        bytes memory extraData =
            abi.encodePacked(hex"00", FULFILLER, uint256(4000), signedOrderR, signedOrderS, context);

        AdvancedOrder advancedOrder = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(1),
            denominator: uint120(1),
            signature: orderSignature,
            extraData: extraData
        });

        // mints
        vm.prank(OWNER);
        erc20Token.transfer(
            FULFILLER,
            considerationItems[0].startAmount + considerationItems[1].startAmount + considerationItems[2].startAmount
                + considerationItems[3].startAmount
        );
        vm.prank(OWNER);
        erc1155Token.safeMint(FULFILLER, offerItems[0].identifierOrCriteria, offerItems[0].startAmount, new bytes(0));

        // approvals
        vm.prank(OFFERER);
        erc1155Token.setApprovalForAll(address(seaport), true);
        vm.prank(FULFILLER);
        erc20Token.approve(
            address(seaport),
            considerationItems[0].startAmount + considerationItems[1].startAmount + considerationItems[2].startAmount
                + considerationItems[3].startAmount
        );

        // fulfill
        seaport.fulfillAdvancedOrder(advancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);
    }
}

// solhint-enable func-name-mixedcase, private-vars-leading-underscore
