// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ImmutableSeaportBaseTest} from "./ImmutableSeaportBase.t.sol";


import {Test} from "forge-std/Test.sol";
import {ImmutableSeaportTestHelper} from "./ImmutableSeaportTestHelper.t.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport/ImmutableSeaport.sol";
import {ImmutableSignedZone} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";

import {ConduitController} from "seaport-core/src/conduit/ConduitController.sol";
import {Consideration} from "seaport-core/src/lib/Consideration.sol";
import {OrderParameters, OrderComponents, Order, AdvancedOrder, FulfillmentComponent, FulfillmentComponent, CriteriaResolver} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "seaport-types/src/lib/ConsiderationEnums.sol";

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

// A wallet rather than an EOA needs to be used for the seller because code in forge detects
// the seller as a contract when created it is created with makeAddr.
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
    SellerWallet public sellerWallet;
    TestERC721 public erc721;
    uint256 public nftId;

    function setUp() public override {
        super.setUp();
        _setFulfillerAndZone(buyer, address(immutableSignedZone));
        sellerWallet = new SellerWallet();
        nftId = 1;
        vm.deal(buyer, 10 ether);
    }


    function testFulfillFullRestrictedOrder() public {
        _checkFulfill(OrderType.FULL_RESTRICTED);
    }

    function testFulfillPartialRestrictedOrder() public {
        _checkFulfill(OrderType.PARTIAL_RESTRICTED);
    }


    function testRejectUnsupportedZones() public {
        // Create order with random zone
        address randomZone = makeAddr("randomZone");
        AdvancedOrder memory order = _prepareCheckFulfill(randomZone);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ImmutableSeaport.InvalidZone.selector, randomZone));
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    }

    function testRejectFullOpenOrder() public {
        AdvancedOrder memory order = _prepareCheckFulfill(OrderType.FULL_OPEN);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ImmutableSeaport.OrderNotRestricted.selector, uint8(OrderType.FULL_OPEN)));
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    }

    function testRejectDisabledZone() public {
        AdvancedOrder memory order = _prepareCheckFulfill();

        vm.prank(owner);
        immutableSeaport.setAllowedZone(address(immutableSignedZone), false);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ImmutableSeaport.InvalidZone.selector, address(immutableSignedZone)));
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    }

    function testRejectWrongSigner() public {
        uint256 wrongSigner = 1;
        AdvancedOrder memory order = _prepareCheckFulfill(wrongSigner);

        // The algorithm inside fulfillAdvancedOrder uses ecRecover to determine the signer. If the
        // information going in is wrong, then the wrong signer will be derived.
        address derivedBadSigner = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerNotActive.selector, derivedBadSigner));
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    }

    function testRejectInvalidExtraData() public {
        AdvancedOrder memory order = _prepareCheckFulfillWithBadExtraData();

        // The algorithm inside fulfillAdvancedOrder uses ecRecover to determine the signer. If the
        // information going in is wrong, then the wrong signer will be derived.
        address derivedBadSigner = 0xcE810B9B83082C93574784f403727369c3FE6955;

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerNotActive.selector, derivedBadSigner));
        immutableSeaport.fulfillAdvancedOrder{value: 10 ether}(order, new CriteriaResolver[](0), conduitKey, buyer);
    }


    function _checkFulfill(OrderType _orderType) internal {
        AdvancedOrder memory order = _prepareCheckFulfill(_orderType);

        // Record balances before
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

    function _prepareCheckFulfill() internal returns (AdvancedOrder memory) {
        return _prepareCheckFulfill(OrderType.PARTIAL_RESTRICTED, address(immutableSignedZone), immutableSignerPkey, false);
    }

    function _prepareCheckFulfill(OrderType _orderType) internal returns (AdvancedOrder memory) {
        return _prepareCheckFulfill(_orderType, address(immutableSignedZone), immutableSignerPkey, false);
    }


    function _prepareCheckFulfill(address _zone) internal returns (AdvancedOrder memory) {
        return _prepareCheckFulfill(OrderType.PARTIAL_RESTRICTED, _zone, immutableSignerPkey, false);
    }

    function _prepareCheckFulfill(uint256 _signer) internal returns (AdvancedOrder memory) {
        return _prepareCheckFulfill(OrderType.PARTIAL_RESTRICTED, address(immutableSignedZone), _signer, false);
    }

    function _prepareCheckFulfillWithBadExtraData() internal returns (AdvancedOrder memory) {
        return _prepareCheckFulfill(OrderType.PARTIAL_RESTRICTED, address(immutableSignedZone), immutableSignerPkey, true);
    }


    function _prepareCheckFulfill(OrderType _orderType, address _zone, uint256 _signer, bool _useBadExtraData) internal returns (AdvancedOrder memory) {
        // Deploy test ERC721
        erc721 = new TestERC721();
        erc721.mint(address(sellerWallet), nftId);
        sellerWallet.setApprovalForAll(address(erc721), conduitAddress);
        uint64 expiration = uint64(block.timestamp + 90);

        // Create order
        OrderParameters memory orderParams = OrderParameters({
            offerer: address(sellerWallet),
            zone: _zone,
            offer: _createOfferItems(address(erc721), nftId),
            consideration: _createConsiderationItems(address(sellerWallet), 10 ether),
            orderType: _orderType,
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
        bytes memory extraData = _generateSip7Signature(orderHash, buyer, _signer, expiration, orderParams.consideration);
        if (_useBadExtraData) {
            orderParams.consideration[0].recipient = payable(buyer);
            extraData = _generateSip7Signature(orderHash, buyer, _signer, expiration, orderParams.consideration);
        }
        bytes memory signature = _signOrder(sellerPkey, orderHash);

        AdvancedOrder memory order = AdvancedOrder({ parameters: orderParams, numerator: 1, denominator: 1, signature: signature, extraData: extraData });
        return order;
    }
}