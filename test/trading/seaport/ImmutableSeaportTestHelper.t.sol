// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ZoneParameters, ConsiderationItem, OfferItem, ReceivedItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";


abstract contract ImmutableSeaportTestHelper is Test {
    bytes internal constant CONSIDERATION_BYTES =
        abi.encodePacked("Consideration(", "ReceivedItem[] consideration", ")");

    bytes internal constant RECEIVED_ITEM_BYTES =
        abi.encodePacked(
            "ReceivedItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifier,",
            "uint256 amount,",
            "address recipient",
            ")"
        );

    bytes32 internal constant RECEIVED_ITEM_TYPEHASH = keccak256(RECEIVED_ITEM_BYTES);

    bytes32 internal constant CONSIDERATION_TYPEHASH =
        keccak256(abi.encodePacked(CONSIDERATION_BYTES, RECEIVED_ITEM_BYTES));

    string public constant ZONE_NAME = "ImmutableSignedZone";
    string public constant VERSION = "1.0";

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

    function _deriveConsiderationHash(ReceivedItem[] calldata consideration) external pure returns (bytes32) {
        uint256 numberOfItems = consideration.length;
        bytes32[] memory considerationHashes = new bytes32[](numberOfItems);
        for (uint256 i; i < numberOfItems; i++) {
            considerationHashes[i] = keccak256(
                abi.encode(
                    RECEIVED_ITEM_TYPEHASH,
                    consideration[i].itemType,
                    consideration[i].token,
                    consideration[i].identifier,
                    consideration[i].amount,
                    consideration[i].recipient
                )
            );
        }
        return keccak256(abi.encode(CONSIDERATION_TYPEHASH, keccak256(abi.encodePacked(considerationHashes))));
    }


    function _signOrder(uint256 signerPkey, bytes32 orderHash) internal view returns (bytes memory) {
        return _signOrder(signerPkey, orderHash, 0, "");
    }

    function _signOrder(
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
        //console.logBytes32(domainSeparator);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SignedOrder(address fulfiller,uint64 expiration,bytes32 orderHash,bytes context)"),
                theFulfiller,
                expiration,
                orderHash,
                keccak256(context)
            )
        );
        //console.logBytes32(structHash);

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        //console.logBytes32(digest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPkey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _convertSignatureToEIP2098(bytes calldata signature) external pure returns (bytes memory) {
        if (signature.length == 64) {
            return signature;
        }
        if (signature.length != 65) {
            revert("Invalid signature length");
        }
        return abi.encodePacked(signature[0:64]);
    }

    function _convertToBytesWithoutArrayLength(bytes32[] memory _orders) internal view returns (bytes memory) {
        bytes memory data = abi.encodePacked(_orders);
        return this._stripArrayLength(data);
    }
    function _stripArrayLength(bytes calldata _data) external pure returns (bytes memory) {
        return _data[32:_data.length];
    }
} 