// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SigningTestHelper} from "./utils/SigningTestHelper.t.sol";
import {ItemType} from "seaport-types-16/src/lib/ConsiderationEnums.sol";
import {ZoneParameters, ConsiderationItem, OfferItem, ReceivedItem, SpentItem} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {Math} from "openzeppelin-contracts-5.0.2/utils/math/Math.sol";



abstract contract ImmutableSeaportTestHelper is Test, SigningTestHelper {
    string public constant ZONE_NAME = "ImmutableSignedZone";
    string public constant VERSION = "3.0";

    address private theFulfiller;

    address private theZone;

    function _setFulfillerAndZone(address _fulfiller, address _zone) internal {
        theFulfiller = _fulfiller;
        theZone = _zone;
    }

    // Helper functions
    function _createZoneParameters(bytes memory _extraData) internal returns (ZoneParameters memory) {
        bytes32 orderHash = keccak256("0x1234");
        return _createZoneParameters(_extraData, orderHash, _createMockConsideration(10));
    }

    function _createZoneParameters(bytes memory _extraData, bytes32 _orderHash) internal returns (ZoneParameters memory) {
        return _createZoneParameters(_extraData, _orderHash, _createMockConsideration(10));
    }

    function _createZoneParameters(bytes memory _extraData, bytes32 _orderHash, ReceivedItem[] memory _consideration) internal view returns (ZoneParameters memory) {
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = _orderHash;
        return _createZoneParameters(_extraData, _orderHash, orderHashes, _consideration);
    }

    function _createZoneParameters(bytes memory _extraData, bytes32 _orderHash, bytes32[] memory _orderHashes, ReceivedItem[] memory _consideration) internal view returns (ZoneParameters memory) {
        return ZoneParameters({
            orderHash: _orderHash,
            fulfiller: theFulfiller,
            offerer: address(0),
            offer: new SpentItem[](0),
            consideration: _consideration,
            extraData: _extraData,
            orderHashes: _orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
    }

    function _createMockConsideration(uint256 count) internal returns (ReceivedItem[] memory) {
        ReceivedItem[] memory consideration = new ReceivedItem[](count);
        for (uint256 i = 0; i < count; i++) {
            address payable recipient = payable(makeAddr(string(abi.encodePacked("recipient", vm.toString(i)))));
            address payable token = payable(makeAddr(string(abi.encodePacked("token", vm.toString(i)))));
            consideration[i] = ReceivedItem({
                itemType: ItemType.NATIVE,
                token: token,
                identifier: 123,
                amount: 12,
                recipient: recipient
            });
        }
        return consideration;
    }

    function _convertConsiderationToReceivedItems(ConsiderationItem[] memory _items) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](_items.length);
        for (uint256 i = 0; i < _items.length; i++) {
            receivedItems[i] = ReceivedItem({
                itemType: _items[i].itemType,
                token: _items[i].token,
                identifier: _items[i].identifierOrCriteria,
                amount: _items[i].startAmount,
                recipient: _items[i].recipient
            });
        }
        return receivedItems;
    }

    function _createConsiderationItems(address recipient, uint256 amount) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: amount,
            endAmount: amount,
            recipient: payable(recipient)
        });
        return consideration;
    }

    function _deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems
    ) public pure returns (bytes32) {
        return _deriveReceivedItemsHash(receivedItems, 1, 1);
    }

    function _deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems,
        uint256 scalingFactorNumerator,
        uint256 scalingFactorDenominator
    ) public pure returns (bytes32) {
        uint256 numberOfItems = receivedItems.length;
        bytes memory receivedItemsHash = new bytes(0); // Explicitly initialize to empty bytes

        for (uint256 i; i < numberOfItems; i++) {
            receivedItemsHash = abi.encodePacked(
                receivedItemsHash,
                receivedItems[i].itemType,
                receivedItems[i].token,
                receivedItems[i].identifier,
                Math.mulDiv(receivedItems[i].amount, scalingFactorNumerator, scalingFactorDenominator),
                receivedItems[i].recipient
            );
        }

        return keccak256(receivedItemsHash);
    }

    function _signOrder(uint256 _signerPkey, bytes32 _orderHash) internal view returns (bytes memory) {
        // For the purposes of testing, the offerer wallet will always return valid for signature checks
        return abi.encodePacked("Hello!");
    }

    function _signSIP7Order(
        uint256 _signerPkey,
        bytes32 orderHash,
        uint64 expiration,
        bytes memory context
    ) internal view returns (bytes memory) {
        uint256 chainId = block.chainid;
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(ZONE_NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                theZone
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SignedOrder(address fulfiller,uint64 expiration,bytes32 orderHash,bytes context)"),
                theFulfiller,
                expiration,
                orderHash,
                keccak256(context)
            )
        );

        bytes32 digest = ECDSA.toTypedDataHash(domainSeparator, structHash);

        return _signCompact(_signerPkey, digest);
    }

    // Helper functions
    function _createOfferItems(address token, uint256 tokenId) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: token,
            identifierOrCriteria: tokenId,
            startAmount: 1,
            endAmount: 1
        });
        return offer;
    }

    function _generateSip7Signature(bytes32 orderHash, address fulfiller, uint256 signerPkey, uint64 _expiration, ConsiderationItem[] memory _consideration) internal view returns (bytes memory) {
        ReceivedItem[] memory receivedItems = _convertConsiderationToReceivedItems(_consideration);
        bytes32 substandard3Data = this._deriveReceivedItemsHash(receivedItems);
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = orderHash;
        bytes memory substandard4Data = abi.encode(orderHashes);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data, bytes1(0x04), substandard4Data);

        bytes memory signature = _signSIP7Order(signerPkey, orderHash, _expiration, context);
        return abi.encodePacked(
            bytes1(0),
            fulfiller,
            _expiration,
            signature,
            context
        );
    }
}