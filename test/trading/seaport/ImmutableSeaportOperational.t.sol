// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ImmutableSeaportBaseTest} from "./ImmutableSeaportBase.t.sol";


import "forge-std/Test.sol";
import {ImmutableSeaportTestHelper} from "./ImmutableSeaportTestHelper.t.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport/ImmutableSeaport.sol";
import {ImmutableSignedZone} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";

import {ConduitController} from "seaport-core/src/conduit/ConduitController.sol";
import {Conduit} from "seaport-core/src/conduit/Conduit.sol";
import {Consideration} from "seaport-core/src/lib/Consideration.sol";
import {OrderParameters, OrderComponents, Order, AdvancedOrder, FulfillmentComponent, FulfillmentComponent, CriteriaResolver} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ConsiderationItem, OfferItem, ReceivedItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";




contract TestERC721 is ERC721("Test721", "TST721") {
    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }
}

contract SellerWallet {
    bytes4 private constant SELECTOR_ERC1271_BYTES_BYTES = 0x20c13b0b;
    bytes4 private constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

    function isValidSignature(bytes calldata /*_data */, bytes calldata /*_signatures*/) external pure returns (bytes4) {
//        if (_signatureValidationInternal(_subDigest(keccak256(_data)), _signatures)) {
            return SELECTOR_ERC1271_BYTES_BYTES;
        // }
        // return 0;
    }

    function isValidSignature(bytes32 /*_hash*/, bytes calldata /*_signatures*/) external pure returns (bytes4) {
        // if (_signatureValidationInternal(_subDigest(_hash), _signatures)) {
            return SELECTOR_ERC1271_BYTES32_BYTES;
        // }
        // return 0;
    }

    function setApprovalForAll(address _erc721, address _seaport) external {
        ERC721(_erc721).setApprovalForAll(_seaport, true);
    }

    receive() external payable { }
}




contract ImmutableSeaportOperationalTest is ImmutableSeaportBaseTest, ImmutableSeaportTestHelper {
    function setUp() public override {
        super.setUp();
        _setFulfillerAndZone(buyer, address(immutableSignedZone));
    }


    function testFulfillFullRestrictedOrder() public {
        SellerWallet sellerWallet = new SellerWallet();

        // Deploy test ERC721
        TestERC721 erc721 = new TestERC721();
        uint256 nftId = 1;
        //erc721.mint(seller, nftId);
        erc721.mint(address(sellerWallet), nftId);
        sellerWallet.setApprovalForAll(address(erc721), conduitAddress);
        uint64 expiration = uint64(block.timestamp + 90);

        // Create order
        OrderParameters memory orderParams = OrderParameters({
            offerer: address(sellerWallet),
            zone: address(immutableSignedZone),
            offer: _createOfferItems(address(erc721), nftId),
            consideration: _createConsiderationItems(address(sellerWallet), 10 ether),
            orderType: OrderType.FULL_RESTRICTED,
            startTime: 0,
            endTime: expiration,
            zoneHash: bytes32(0),
            salt: 0,
            conduitKey: conduitKey,
            totalOriginalConsiderationItems: 1
        });

        OrderComponents memory orderComponents = OrderComponents({
            offerer: orderParams.offerer,
            zone: orderParams.zone,
            offer: orderParams.offer,
            consideration: orderParams.consideration,
            orderType: orderParams.orderType,
            startTime: orderParams.startTime,
            endTime: orderParams.endTime,
            zoneHash: orderParams.zoneHash,
            salt: orderParams.salt,
            conduitKey: orderParams.conduitKey,
            counter: 0
        });

        bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
        bytes memory extraData = _generateSip7Signature(orderHash, buyer, immutableSignerPkey, expiration, orderParams.consideration);
        bytes memory signature = _signOrder(sellerPkey, orderHash);

        AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);

        // Record balances before
        vm.deal(buyer, 10 ether);
        uint256 sellerBalanceBefore = address(sellerWallet).balance;
        uint256 buyerBalanceBefore = address(buyer).balance;

        // Fulfill order
        vm.prank(buyer);
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);

        // Verify results
        assertEq(erc721.ownerOf(nftId), buyer, "Owner of NFT not buyer");
        assertEq(address(sellerWallet).balance, sellerBalanceBefore + 10 ether, "Seller incorrect final balance");
        assertEq(address(buyer).balance, buyerBalanceBefore - 10 ether, "Buyer incorrect final balance");
    }

    // function testFulfillPartialRestrictedOrder() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Create order
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: address(immutableSignedZone),
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.PARTIAL_RESTRICTED,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
    //     bytes memory extraData = _generateSip7Signature(orderHash, buyer);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Record balances before
    //     uint256 sellerBalanceBefore = address(seller).balance;
    //     uint256 buyerBalanceBefore = address(buyer).balance;

    //     // Fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);

    //     // Verify results
    //     assertEq(erc721.ownerOf(nftId), buyer);
    //     assertEq(address(seller).balance, sellerBalanceBefore + 10 ether);
    //     assertLt(address(buyer).balance, buyerBalanceBefore - 10 ether);
    // }

    // function testRejectUnsupportedZones() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Create order with random zone
    //     address randomZone = makeAddr("randomZone");
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: randomZone,
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.FULL_RESTRICTED,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
    //     bytes memory extraData = _generateSip7Signature(orderHash, buyer);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Try to fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     vm.expectRevert("InvalidZone");
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    // }

    // function testRejectFullOpenOrder() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Create order
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: address(immutableSignedZone),
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.FULL_OPEN,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
    //     bytes memory extraData = _generateSip7Signature(orderHash, buyer);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Try to fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     vm.expectRevert("OrderNotRestricted");
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    // }

    // function testRejectDisabledZone() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Disable the zone
    //     vm.prank(owner);
    //     immutableSeaport.setAllowedZone(address(immutableSignedZone), false);

    //     // Create order
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: address(immutableSignedZone),
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.PARTIAL_RESTRICTED,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
    //     bytes memory extraData = _generateSip7Signature(orderHash, buyer);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Try to fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     vm.expectRevert("InvalidZone");
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    // }

    // function testRejectWrongSigner() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Create order
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: address(immutableSignedZone),
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.PARTIAL_RESTRICTED,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
        
    //     // Sign with wrong signer
    //     (address wrongSigner, uint256 wrongSignerPkey) = makeAddrAndKey("wrongSigner");
    //     bytes memory extraData = _generateSip7SignatureWithSigner(orderHash, buyer, wrongSignerPkey);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Try to fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerNotActive.selector, wrongSigner));
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    // }

    // function testRejectInvalidExtraData() public {
    //     // Deploy test ERC721
    //     TestERC721 erc721 = new TestERC721();
    //     uint256 nftId = 1;
    //     erc721.mint(seller, nftId);
    //     vm.prank(seller);
    //     erc721.setApprovalForAll(address(immutableSeaport), true);

    //     // Create order
    //     OrderParameters memory orderParams = OrderParameters({
    //         offerer: seller,
    //         zone: address(immutableSignedZone),
    //         offer: _createOfferItems(address(erc721), nftId),
    //         consideration: _createConsiderationItems(seller, 10 ether),
    //         orderType: OrderType.PARTIAL_RESTRICTED,
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0),
    //         salt: 0,
    //         conduitKey: conduitKey,
    //         totalOriginalConsiderationItems: 1
    //     });

    //     OrderComponents memory orderComponents = OrderComponents({
    //         offerer: orderParams.offerer,
    //         zone: orderParams.zone,
    //         offer: orderParams.offer,
    //         consideration: orderParams.consideration,
    //         orderType: orderParams.orderType,
    //         startTime: orderParams.startTime,
    //         endTime: orderParams.endTime,
    //         zoneHash: orderParams.zoneHash,
    //         salt: orderParams.salt,
    //         conduitKey: orderParams.conduitKey,
    //         counter: 0
    //     });

    //     bytes32 orderHash = immutableSeaport.getOrderHash(orderComponents);
        
    //     // Generate signature with bad order hash
    //     bytes memory extraData = _generateSip7Signature(bytes32(0), buyer);
    //     bytes memory signature = _signOrder(sellerPkey, orderHash);

    //     AdvancedOrder memory order = AdvancedOrder(orderParams, 1, 1, signature, extraData);
    //     // Order memory order = Order(orderParams, signature);
    //     // order.extraData = extraData;

    //     // Try to fulfill order
    //     vm.deal(buyer, 10 ether);
    //     vm.prank(buyer);
    //     vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SubstandardViolation.selector, 
    //         3, "invalid consideration hash", orderHash));
    //     immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    // }
} 