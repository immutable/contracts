// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ItemType, OrderType} from "seaport-types-16/src/lib/ConsiderationEnums.sol";
import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    OrderComponents,
    OfferItem,
    OrderParameters,
    ReceivedItem
} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {ConduitController} from "../../../contracts/trading/seaport16/conduit/ConduitController.sol";
import {ImmutableSeaportHarness} from "./ImmutableSeaportHarness.t.sol";
import {IImmutableERC1155} from "../seaport/utils/IImmutableERC1155.t.sol";
import {IImmutableERC721} from "../seaport/utils/IImmutableERC721.t.sol";
import {IOperatorAllowlistUpgradeable} from "../seaport/utils/IOperatorAllowlistUpgradeable.t.sol";
import {SigningTestHelper} from "../seaport/utils/SigningTestHelper.t.sol";
import {IImmutableSignedZoneV3Harness} from "./zones/immutable-signed-zone/v3/IImmutableSignedZoneV3Harness.t.sol";

// solhint-disable func-name-mixedcase, private-vars-leading-underscore

contract ImmutableSeaportSignedZoneV3IntegrationTest is Test, SigningTestHelper {
    // Foundry artifacts allow the test to deploy contracts separately that aren't compatible with
    // the solidity version compiler that the test and its dependencies resolve to.
    string private constant OPERATOR_ALLOWLIST_ARTIFACT =
        "./foundry-out/OperatorAllowlistUpgradeable.sol/OperatorAllowlistUpgradeable.json";
    string private constant ERC1155_ARTIFACT = "./foundry-out/ImmutableERC1155.sol/ImmutableERC1155.json";
    string private constant ERC20_ARTIFACT =
        "./foundry-out/ImmutableERC20FixedSupplyNoBurn.sol/ImmutableERC20FixedSupplyNoBurn.json";
    string private constant ERC721_ARTIFACT = "./foundry-out/ImmutableERC721.sol/ImmutableERC721.json";
    string private constant ZONE_ARTIFACT =
        "./foundry-out/ImmutableSignedZoneV3Harness.t.sol/ImmutableSignedZoneV3Harness.json";

    address private immutable OWNER = makeAddr("owner");
    address private immutable ZONE_MANAGER = makeAddr("zone_manager");
    address private immutable SIGNER;
    uint256 private immutable SIGNER_PRIVATE_KEY;
    address private immutable FULFILLER = makeAddr("fulfiller");
    address private immutable FULFILLER_TWO = makeAddr("fulfiller_two");
    address private immutable OFFERER;
    uint256 private immutable OFFERER_PRIVATE_KEY;
    address private immutable PROTOCOL_FEE_RECEIVER = makeAddr("protocol_fee_receiver");
    address private immutable ROYALTY_FEE_RECEIVER = makeAddr("royalty_fee_receiver");
    address private immutable ECOSYSTEM_FEE_RECEIVER = makeAddr("ecosystem_fee_receiver");

    ImmutableSeaportHarness private seaport;
    IImmutableSignedZoneV3Harness private zone;
    IERC20 private erc20Token;
    IImmutableERC1155 private erc1155Token;
    IImmutableERC721 private erc721Token;

    constructor() {
        (SIGNER, SIGNER_PRIVATE_KEY) = makeAddrAndKey("signer");
        (OFFERER, OFFERER_PRIVATE_KEY) = makeAddrAndKey("offerer");
    }

    function setUp() public {
        // operator allowlist
        IOperatorAllowlistUpgradeable operatorAllowlist =
            IOperatorAllowlistUpgradeable(deployCode(OPERATOR_ALLOWLIST_ARTIFACT));
        operatorAllowlist.initialize(OWNER, OWNER, OWNER);

        // tokens
        erc20Token =
            IERC20(deployCode(ERC20_ARTIFACT, abi.encode("TestERC20", "ERC20", type(uint256).max, OWNER, OWNER)));
        erc721Token = IImmutableERC721(
            deployCode(
                ERC721_ARTIFACT,
                abi.encode(
                    OWNER, "TestERC721", "ERC721", "", "", address(operatorAllowlist), ROYALTY_FEE_RECEIVER, uint96(100)
                )
            )
        );
        vm.prank(OWNER);
        erc721Token.grantMinterRole(OWNER);
        erc1155Token = IImmutableERC1155(
            deployCode(
                ERC1155_ARTIFACT,
                abi.encode(OWNER, "TestERC1155", "", "", address(operatorAllowlist), ROYALTY_FEE_RECEIVER, uint96(100))
            )
        );
        vm.prank(OWNER);
        erc1155Token.grantMinterRole(OWNER);

        // zone
        zone = IImmutableSignedZoneV3Harness(
            deployCode(
                ZONE_ARTIFACT,
                abi.encode("MyZoneName", "https://www.immutable.com", "https://www.immutable.com/docs", OWNER)
            )
        );
        vm.prank(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, ZONE_MANAGER);
        vm.prank(ZONE_MANAGER);
        zone.addSigner(SIGNER);

        // seaport
        ConduitController conduitController = new ConduitController();
        seaport = new ImmutableSeaportHarness(address(conduitController), OWNER);
        vm.prank(OWNER);
        seaport.setAllowedZone(address(zone), true);

        // operator allowlist addresses
        address[] memory allowlistAddress = new address[](1);
        allowlistAddress[0] = address(seaport);
        vm.prank(OWNER);
        operatorAllowlist.addAddressesToAllowlist(allowlistAddress);
    }

    function test_fulfillAdvancedOrder_withCompleteFulfilment() public {
        // offer items
        OfferItem[] memory offerItems = new OfferItem[](1);
        offerItems[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: address(erc721Token),
            identifierOrCriteria: uint256(50),
            startAmount: uint256(1),
            endAmount: uint256(1)
        });

        // consideration items
        ConsiderationItem[] memory originalConsiderationItems = new ConsiderationItem[](1);
        // original item
        originalConsiderationItems[0] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(200_000_000_000_000_000_000), // 200^18
            endAmount: uint256(200_000_000_000_000_000_000), // 200^18
            recipient: payable(OFFERER)
        });

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](4);
        considerationItems[0] = originalConsiderationItems[0];
        // protocol fee - 2%
        considerationItems[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(4_000_000_000_000_000_000),
            endAmount: uint256(4_000_000_000_000_000_000),
            recipient: payable(PROTOCOL_FEE_RECEIVER)
        });
        // royalty fee - 1%
        considerationItems[2] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(2_000_000_000_000_000_000),
            endAmount: uint256(2_000_000_000_000_000_000),
            recipient: payable(ROYALTY_FEE_RECEIVER)
        });
        // ecosystem fee - 3%
        considerationItems[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(6_000_000_000_000_000_000),
            endAmount: uint256(6_000_000_000_000_000_000),
            recipient: payable(ECOSYSTEM_FEE_RECEIVER)
        });

        // order
        OrderParameters memory orderParameters = OrderParameters({
            offerer: OFFERER,
            zone: address(zone),
            offer: offerItems,
            consideration: considerationItems,
            orderType: OrderType.FULL_RESTRICTED,
            startTime: uint256(0),
            endTime: uint256(5000),
            zoneHash: bytes32(0),
            salt: uint256(123),
            conduitKey: bytes32(0),
            totalOriginalConsiderationItems: uint256(1)
        });

        // order hash
        bytes32 orderHash = seaport.getOrderHash(
            OrderComponents({
                offerer: orderParameters.offerer,
                zone: orderParameters.zone,
                offer: orderParameters.offer,
                consideration: originalConsiderationItems,
                orderType: orderParameters.orderType,
                startTime: orderParameters.startTime,
                endTime: orderParameters.endTime,
                zoneHash: orderParameters.zoneHash,
                salt: orderParameters.salt,
                conduitKey: orderParameters.conduitKey,
                counter: seaport.getCounter(orderParameters.offerer)
            })
        );

        // order signature
        bytes memory orderSignature;
        {
            bytes32 orderDigest = seaport.exposed_deriveEIP712Digest(seaport.exposed_domainSeparator(), orderHash);
            orderSignature = _sign(OFFERER_PRIVATE_KEY, orderDigest);
        }

        // extra data
        bytes memory extraData;
        {
            ReceivedItem[] memory expectedReceivedItems = new ReceivedItem[](4);
            expectedReceivedItems[0] = ReceivedItem({
                itemType: considerationItems[0].itemType,
                token: considerationItems[0].token,
                identifier: considerationItems[0].identifierOrCriteria,
                amount: considerationItems[0].startAmount,
                recipient: considerationItems[0].recipient
            });
            expectedReceivedItems[1] = ReceivedItem({
                itemType: considerationItems[1].itemType,
                token: considerationItems[1].token,
                identifier: considerationItems[1].identifierOrCriteria,
                amount: considerationItems[1].startAmount,
                recipient: considerationItems[1].recipient
            });
            expectedReceivedItems[2] = ReceivedItem({
                itemType: considerationItems[2].itemType,
                token: considerationItems[2].token,
                identifier: considerationItems[2].identifierOrCriteria,
                amount: considerationItems[2].startAmount,
                recipient: considerationItems[2].recipient
            });
            expectedReceivedItems[3] = ReceivedItem({
                itemType: considerationItems[3].itemType,
                token: considerationItems[3].token,
                identifier: considerationItems[3].identifierOrCriteria,
                amount: considerationItems[3].startAmount,
                recipient: considerationItems[3].recipient
            });
            bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
            bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
            bytes32 eip712SignedOrderHash =
                zone.exposed_deriveSignedOrderHash(FULFILLER, uint64(4000), orderHash, context);
            extraData = abi.encodePacked(
                bytes1(0),
                FULFILLER,
                uint64(4000),
                _signCompact(
                    SIGNER_PRIVATE_KEY, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)
                ),
                context
            );
        }

        // advanced order
        AdvancedOrder memory advancedOrder = AdvancedOrder({
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
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            )
        );
        vm.prank(OWNER);
        erc721Token.safeMint(OFFERER, offerItems[0].identifierOrCriteria);

        // approvals
        vm.prank(OFFERER);
        erc721Token.setApprovalForAll(address(seaport), true);
        vm.prank(FULFILLER);
        erc20Token.approve(address(seaport), type(uint256).max);

        // fulfillment
        vm.prank(FULFILLER);
        seaport.fulfillAdvancedOrder(advancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);

        // assertions
        assertEq(erc721Token.balanceOf(OFFERER), 0);
        assertEq(erc721Token.balanceOf(FULFILLER), offerItems[0].startAmount);
        assertEq(erc20Token.balanceOf(OFFERER), considerationItems[0].startAmount);
        assertEq(erc20Token.balanceOf(FULFILLER), 0);
        assertEq(erc20Token.balanceOf(PROTOCOL_FEE_RECEIVER), considerationItems[1].startAmount);
        assertEq(erc20Token.balanceOf(ROYALTY_FEE_RECEIVER), considerationItems[2].startAmount);
        assertEq(erc20Token.balanceOf(ECOSYSTEM_FEE_RECEIVER), considerationItems[3].startAmount);
    }

    function test_fulfillAdvancedOrder_withPartialFill() public {
        // offer items
        OfferItem[] memory offerItems = new OfferItem[](1);
        offerItems[0] = OfferItem({
            itemType: ItemType.ERC1155,
            token: address(erc1155Token),
            identifierOrCriteria: uint256(50),
            startAmount: uint256(100),
            endAmount: uint256(100)
        });

        // consideration items
        ConsiderationItem[] memory originalConsiderationItems = new ConsiderationItem[](1);
        // original item
        originalConsiderationItems[0] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(200_000_000_000_000_000_000), // 200^18
            endAmount: uint256(200_000_000_000_000_000_000), // 200^18
            recipient: payable(OFFERER)
        });

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](4);
        considerationItems[0] = originalConsiderationItems[0];
        // protocol fee - 2%
        considerationItems[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(4_000_000_000_000_000_000),
            endAmount: uint256(4_000_000_000_000_000_000),
            recipient: payable(PROTOCOL_FEE_RECEIVER)
        });
        // royalty fee - 1%
        considerationItems[2] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(2_000_000_000_000_000_000),
            endAmount: uint256(2_000_000_000_000_000_000),
            recipient: payable(ROYALTY_FEE_RECEIVER)
        });
        // ecosystem fee - 3%
        considerationItems[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(6_000_000_000_000_000_000),
            endAmount: uint256(6_000_000_000_000_000_000),
            recipient: payable(ECOSYSTEM_FEE_RECEIVER)
        });

        // order
        OrderParameters memory orderParameters = OrderParameters({
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

        // order hash
        bytes32 orderHash = seaport.getOrderHash(
            OrderComponents({
                offerer: orderParameters.offerer,
                zone: orderParameters.zone,
                offer: orderParameters.offer,
                consideration: originalConsiderationItems,
                orderType: orderParameters.orderType,
                startTime: orderParameters.startTime,
                endTime: orderParameters.endTime,
                zoneHash: orderParameters.zoneHash,
                salt: orderParameters.salt,
                conduitKey: orderParameters.conduitKey,
                counter: seaport.getCounter(orderParameters.offerer)
            })
        );

        // order signature
        bytes memory orderSignature;
        {
            bytes32 orderDigest = seaport.exposed_deriveEIP712Digest(seaport.exposed_domainSeparator(), orderHash);
            orderSignature = _sign(OFFERER_PRIVATE_KEY, orderDigest);
        }

        // extra data
        bytes memory extraData;
        {
            ReceivedItem[] memory expectedReceivedItems = new ReceivedItem[](4);
            expectedReceivedItems[0] = ReceivedItem({
                itemType: considerationItems[0].itemType,
                token: considerationItems[0].token,
                identifier: considerationItems[0].identifierOrCriteria,
                amount: considerationItems[0].startAmount,
                recipient: considerationItems[0].recipient
            });
            expectedReceivedItems[1] = ReceivedItem({
                itemType: considerationItems[1].itemType,
                token: considerationItems[1].token,
                identifier: considerationItems[1].identifierOrCriteria,
                amount: considerationItems[1].startAmount,
                recipient: considerationItems[1].recipient
            });
            expectedReceivedItems[2] = ReceivedItem({
                itemType: considerationItems[2].itemType,
                token: considerationItems[2].token,
                identifier: considerationItems[2].identifierOrCriteria,
                amount: considerationItems[2].startAmount,
                recipient: considerationItems[2].recipient
            });
            expectedReceivedItems[3] = ReceivedItem({
                itemType: considerationItems[3].itemType,
                token: considerationItems[3].token,
                identifier: considerationItems[3].identifierOrCriteria,
                amount: considerationItems[3].startAmount,
                recipient: considerationItems[3].recipient
            });
            bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
            bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
            bytes32 eip712SignedOrderHash =
                zone.exposed_deriveSignedOrderHash(FULFILLER, uint64(4000), orderHash, context);
            extraData = abi.encodePacked(
                bytes1(0),
                FULFILLER,
                uint64(4000),
                _signCompact(
                    SIGNER_PRIVATE_KEY, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)
                ),
                context
            );
        }

        // advanced order, fill 1/100th of the order
        AdvancedOrder memory advancedOrder = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(1),
            denominator: uint120(100),
            signature: orderSignature,
            extraData: extraData
        });

        // mints
        vm.prank(OWNER);
        erc20Token.transfer(
            FULFILLER,
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            ) / 100
        );
        vm.prank(OWNER);
        erc1155Token.safeMint(OFFERER, offerItems[0].identifierOrCriteria, offerItems[0].startAmount, new bytes(0));

        // approvals
        vm.prank(OFFERER);
        erc1155Token.setApprovalForAll(address(seaport), true);
        vm.prank(FULFILLER);
        erc20Token.approve(address(seaport), type(uint256).max);

        // fulfillment
        vm.prank(FULFILLER);
        seaport.fulfillAdvancedOrder(advancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);

        // assertions
        assertEq(
            erc1155Token.balanceOf(OFFERER, offerItems[0].identifierOrCriteria), offerItems[0].startAmount * 99 / 100
        );
        assertEq(
            erc1155Token.balanceOf(FULFILLER, offerItems[0].identifierOrCriteria), offerItems[0].startAmount * 1 / 100
        );
        assertEq(erc20Token.balanceOf(OFFERER), considerationItems[0].startAmount / 100);
        assertEq(erc20Token.balanceOf(FULFILLER), 0);
        assertEq(erc20Token.balanceOf(PROTOCOL_FEE_RECEIVER), considerationItems[1].startAmount / 100);
        assertEq(erc20Token.balanceOf(ROYALTY_FEE_RECEIVER), considerationItems[2].startAmount / 100);
        assertEq(erc20Token.balanceOf(ECOSYSTEM_FEE_RECEIVER), considerationItems[3].startAmount / 100);
    }

    function test_fulfillAdvancedOrder_withMultiplePartialFills() public {
        // offer items
        OfferItem[] memory offerItems = new OfferItem[](1);
        offerItems[0] = OfferItem({
            itemType: ItemType.ERC1155,
            token: address(erc1155Token),
            identifierOrCriteria: uint256(50),
            startAmount: uint256(100),
            endAmount: uint256(100)
        });

        // consideration items
        ConsiderationItem[] memory originalConsiderationItems = new ConsiderationItem[](1);
        // original item
        originalConsiderationItems[0] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(200_000_000_000_000_000_000), // 200^18
            endAmount: uint256(200_000_000_000_000_000_000), // 200^18
            recipient: payable(OFFERER)
        });

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](4);
        considerationItems[0] = originalConsiderationItems[0];
        // protocol fee - 2%
        considerationItems[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(4_000_000_000_000_000_000),
            endAmount: uint256(4_000_000_000_000_000_000),
            recipient: payable(PROTOCOL_FEE_RECEIVER)
        });
        // royalty fee - 1%
        considerationItems[2] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(2_000_000_000_000_000_000),
            endAmount: uint256(2_000_000_000_000_000_000),
            recipient: payable(ROYALTY_FEE_RECEIVER)
        });
        // ecosystem fee - 3%
        considerationItems[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(6_000_000_000_000_000_000),
            endAmount: uint256(6_000_000_000_000_000_000),
            recipient: payable(ECOSYSTEM_FEE_RECEIVER)
        });

        // order
        OrderParameters memory orderParameters = OrderParameters({
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

        // order hash
        bytes32 orderHash = seaport.getOrderHash(
            OrderComponents({
                offerer: orderParameters.offerer,
                zone: orderParameters.zone,
                offer: orderParameters.offer,
                consideration: originalConsiderationItems,
                orderType: orderParameters.orderType,
                startTime: orderParameters.startTime,
                endTime: orderParameters.endTime,
                zoneHash: orderParameters.zoneHash,
                salt: orderParameters.salt,
                conduitKey: orderParameters.conduitKey,
                counter: seaport.getCounter(orderParameters.offerer)
            })
        );

        // order signature
        bytes memory orderSignature;
        {
            bytes32 orderDigest = seaport.exposed_deriveEIP712Digest(seaport.exposed_domainSeparator(), orderHash);
            orderSignature = _sign(OFFERER_PRIVATE_KEY, orderDigest);
        }

        // extra data
        bytes memory extraData;
        {
            ReceivedItem[] memory expectedReceivedItems = new ReceivedItem[](4);
            expectedReceivedItems[0] = ReceivedItem({
                itemType: considerationItems[0].itemType,
                token: considerationItems[0].token,
                identifier: considerationItems[0].identifierOrCriteria,
                amount: considerationItems[0].startAmount,
                recipient: considerationItems[0].recipient
            });
            expectedReceivedItems[1] = ReceivedItem({
                itemType: considerationItems[1].itemType,
                token: considerationItems[1].token,
                identifier: considerationItems[1].identifierOrCriteria,
                amount: considerationItems[1].startAmount,
                recipient: considerationItems[1].recipient
            });
            expectedReceivedItems[2] = ReceivedItem({
                itemType: considerationItems[2].itemType,
                token: considerationItems[2].token,
                identifier: considerationItems[2].identifierOrCriteria,
                amount: considerationItems[2].startAmount,
                recipient: considerationItems[2].recipient
            });
            expectedReceivedItems[3] = ReceivedItem({
                itemType: considerationItems[3].itemType,
                token: considerationItems[3].token,
                identifier: considerationItems[3].identifierOrCriteria,
                amount: considerationItems[3].startAmount,
                recipient: considerationItems[3].recipient
            });
            bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
            bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
            bytes32 eip712SignedOrderHash =
                zone.exposed_deriveSignedOrderHash(FULFILLER, uint64(4000), orderHash, context);
            extraData = abi.encodePacked(
                bytes1(0),
                FULFILLER,
                uint64(4000),
                _signCompact(
                    SIGNER_PRIVATE_KEY, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)
                ),
                context
            );
        }

        // advanced order, fill 1/100th of the order
        AdvancedOrder memory advancedOrder = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(1),
            denominator: uint120(100),
            signature: orderSignature,
            extraData: extraData
        });

        // mints
        vm.prank(OWNER);
        erc20Token.transfer(
            FULFILLER,
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            ) * 2 / 100
        );
        vm.prank(OWNER);
        erc1155Token.safeMint(OFFERER, offerItems[0].identifierOrCriteria, offerItems[0].startAmount, new bytes(0));

        // approvals
        vm.prank(OFFERER);
        erc1155Token.setApprovalForAll(address(seaport), true);
        vm.prank(FULFILLER);
        erc20Token.approve(address(seaport), type(uint256).max);

        // fulfill twice
        vm.prank(FULFILLER);
        seaport.fulfillAdvancedOrder(advancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);
        vm.prank(FULFILLER);
        seaport.fulfillAdvancedOrder(advancedOrder, new CriteriaResolver[](0), bytes32(0), FULFILLER);

        // assertions
        assertEq(
            erc1155Token.balanceOf(OFFERER, offerItems[0].identifierOrCriteria), offerItems[0].startAmount * 98 / 100
        );
        assertEq(
            erc1155Token.balanceOf(FULFILLER, offerItems[0].identifierOrCriteria), offerItems[0].startAmount * 2 / 100
        );
        assertEq(erc20Token.balanceOf(OFFERER), considerationItems[0].startAmount * 2 / 100);
        assertEq(erc20Token.balanceOf(FULFILLER), 0);
        assertEq(erc20Token.balanceOf(PROTOCOL_FEE_RECEIVER), considerationItems[1].startAmount * 2 / 100);
        assertEq(erc20Token.balanceOf(ROYALTY_FEE_RECEIVER), considerationItems[2].startAmount * 2 / 100);
        assertEq(erc20Token.balanceOf(ECOSYSTEM_FEE_RECEIVER), considerationItems[3].startAmount * 2 / 100);
    }

    function test_fulfillAdvancedOrder_withOverfilling() public {
        // offer items
        OfferItem[] memory offerItems = new OfferItem[](1);
        offerItems[0] = OfferItem({
            itemType: ItemType.ERC1155,
            token: address(erc1155Token),
            identifierOrCriteria: uint256(50),
            startAmount: uint256(100),
            endAmount: uint256(100)
        });

        // consideration items
        ConsiderationItem[] memory originalConsiderationItems = new ConsiderationItem[](1);
        // original item
        originalConsiderationItems[0] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(200_000_000_000_000_000_000), // 200^18
            endAmount: uint256(200_000_000_000_000_000_000), // 200^18
            recipient: payable(OFFERER)
        });

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](4);
        considerationItems[0] = originalConsiderationItems[0];
        // protocol fee - 2%
        considerationItems[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(4_000_000_000_000_000_000),
            endAmount: uint256(4_000_000_000_000_000_000),
            recipient: payable(PROTOCOL_FEE_RECEIVER)
        });
        // royalty fee - 1%
        considerationItems[2] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(2_000_000_000_000_000_000),
            endAmount: uint256(2_000_000_000_000_000_000),
            recipient: payable(ROYALTY_FEE_RECEIVER)
        });
        // ecosystem fee - 3%
        considerationItems[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20Token),
            identifierOrCriteria: uint256(0),
            startAmount: uint256(6_000_000_000_000_000_000),
            endAmount: uint256(6_000_000_000_000_000_000),
            recipient: payable(ECOSYSTEM_FEE_RECEIVER)
        });

        // order
        OrderParameters memory orderParameters = OrderParameters({
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

        // order hash
        bytes32 orderHash = seaport.getOrderHash(
            OrderComponents({
                offerer: orderParameters.offerer,
                zone: orderParameters.zone,
                offer: orderParameters.offer,
                consideration: originalConsiderationItems,
                orderType: orderParameters.orderType,
                startTime: orderParameters.startTime,
                endTime: orderParameters.endTime,
                zoneHash: orderParameters.zoneHash,
                salt: orderParameters.salt,
                conduitKey: orderParameters.conduitKey,
                counter: seaport.getCounter(orderParameters.offerer)
            })
        );

        // order signature
        bytes memory orderSignature;
        {
            bytes32 orderDigest = seaport.exposed_deriveEIP712Digest(seaport.exposed_domainSeparator(), orderHash);
            orderSignature = _sign(OFFERER_PRIVATE_KEY, orderDigest);
        }

        // substandard 6 data expected received items
        ReceivedItem[] memory expectedReceivedItems = new ReceivedItem[](4);
        expectedReceivedItems[0] = ReceivedItem({
            itemType: considerationItems[0].itemType,
            token: considerationItems[0].token,
            identifier: considerationItems[0].identifierOrCriteria,
            amount: considerationItems[0].startAmount,
            recipient: considerationItems[0].recipient
        });
        expectedReceivedItems[1] = ReceivedItem({
            itemType: considerationItems[1].itemType,
            token: considerationItems[1].token,
            identifier: considerationItems[1].identifierOrCriteria,
            amount: considerationItems[1].startAmount,
            recipient: considerationItems[1].recipient
        });
        expectedReceivedItems[2] = ReceivedItem({
            itemType: considerationItems[2].itemType,
            token: considerationItems[2].token,
            identifier: considerationItems[2].identifierOrCriteria,
            amount: considerationItems[2].startAmount,
            recipient: considerationItems[2].recipient
        });
        expectedReceivedItems[3] = ReceivedItem({
            itemType: considerationItems[3].itemType,
            token: considerationItems[3].token,
            identifier: considerationItems[3].identifierOrCriteria,
            amount: considerationItems[3].startAmount,
            recipient: considerationItems[3].recipient
        });

        // extra data
        bytes memory extraData1;
        bytes memory extraData2;
        {
            bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
            bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
            bytes32 eip712SignedOrderHash =
                zone.exposed_deriveSignedOrderHash(FULFILLER, uint64(4000), orderHash, context);
            extraData1 = abi.encodePacked(
                bytes1(0),
                FULFILLER,
                uint64(4000),
                _signCompact(
                    SIGNER_PRIVATE_KEY, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)
                ),
                context
            );
        }
        {
            bytes32 substandard6Data = zone.exposed_deriveReceivedItemsHash(expectedReceivedItems, 1, 1);
            bytes memory context = abi.encodePacked(bytes1(0x06), offerItems[0].startAmount, substandard6Data);
            bytes32 eip712SignedOrderHash =
                zone.exposed_deriveSignedOrderHash(FULFILLER_TWO, uint64(4000), orderHash, context);
            extraData2 = abi.encodePacked(
                bytes1(0),
                FULFILLER_TWO,
                uint64(4000),
                _signCompact(
                    SIGNER_PRIVATE_KEY, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)
                ),
                context
            );
        }

        // advanced order, fill 1/2 of the order
        AdvancedOrder memory advancedOrder1 = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(50),
            denominator: uint120(100),
            signature: orderSignature,
            extraData: extraData1
        });

        // advanced order, attempt to fill the whole order
        AdvancedOrder memory advancedOrder2 = AdvancedOrder({
            parameters: orderParameters,
            numerator: uint120(1),
            denominator: uint120(1),
            signature: orderSignature,
            extraData: extraData2
        });

        // mints
        vm.prank(OWNER);
        erc20Token.transfer(
            FULFILLER,
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            ) / 2
        );
        vm.prank(OWNER);
        erc20Token.transfer(
            FULFILLER_TWO,
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            )
        );
        vm.prank(OWNER);
        erc1155Token.safeMint(OFFERER, offerItems[0].identifierOrCriteria, offerItems[0].startAmount, new bytes(0));

        // approvals
        vm.prank(OFFERER);
        erc1155Token.setApprovalForAll(address(seaport), true);
        vm.prank(FULFILLER);
        erc20Token.approve(address(seaport), type(uint256).max);
        vm.prank(FULFILLER_TWO);
        erc20Token.approve(address(seaport), type(uint256).max);

        // fulfill twice
        vm.prank(FULFILLER);
        seaport.fulfillAdvancedOrder(advancedOrder1, new CriteriaResolver[](0), bytes32(0), FULFILLER);
        vm.prank(FULFILLER_TWO);
        seaport.fulfillAdvancedOrder(advancedOrder2, new CriteriaResolver[](0), bytes32(0), FULFILLER_TWO);

        // assertions
        assertEq(erc1155Token.balanceOf(OFFERER, offerItems[0].identifierOrCriteria), 0);
        assertEq(erc1155Token.balanceOf(FULFILLER, offerItems[0].identifierOrCriteria), offerItems[0].startAmount / 2);
        assertEq(
            erc1155Token.balanceOf(FULFILLER_TWO, offerItems[0].identifierOrCriteria), offerItems[0].startAmount / 2
        );
        assertEq(erc20Token.balanceOf(OFFERER), considerationItems[0].startAmount);
        assertEq(erc20Token.balanceOf(FULFILLER), 0);
        assertEq(
            erc20Token.balanceOf(FULFILLER_TWO),
            (
                considerationItems[0].startAmount + considerationItems[1].startAmount
                    + considerationItems[2].startAmount + considerationItems[3].startAmount
            ) / 2
        );
        assertEq(erc20Token.balanceOf(PROTOCOL_FEE_RECEIVER), considerationItems[1].startAmount);
        assertEq(erc20Token.balanceOf(ROYALTY_FEE_RECEIVER), considerationItems[2].startAmount);
        assertEq(erc20Token.balanceOf(ECOSYSTEM_FEE_RECEIVER), considerationItems[3].startAmount);
    }
}

// solhint-enable func-name-mixedcase, private-vars-leading-underscore
