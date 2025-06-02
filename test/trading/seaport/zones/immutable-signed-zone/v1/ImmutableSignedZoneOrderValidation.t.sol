// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ImmutableSignedZone} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";
import {SIP6EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP6EventsAndErrors.sol";
import {ZoneParameters, ReceivedItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";


contract ImmutableSignedZoneOrderValidationTest is Test {
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



    ImmutableSignedZone public zone;
    address public owner;
    address public signer;
    uint256 public signerPkey;
    address public fulfiller;
    uint256 public chainId;
    string public constant ZONE_NAME = "ImmutableSignedZone";
    string public constant VERSION = "1.0";

    function setUp() public {
        // Set up chain ID
        chainId = block.chainid;
        
        // Create test addresses
        owner = makeAddr("owner");
        (signer, signerPkey) = makeAddrAndKey("signer");
        fulfiller = makeAddr("fulfiller");

        // Deploy contract
        vm.startPrank(owner);
        zone = new ImmutableSignedZone(ZONE_NAME, "", "", owner);
        zone.addSigner(signer);
        vm.stopPrank();
    }

    function testValidatesCorrectSignatureWithContext() public {
        bytes32 orderHash = keccak256("0x1234");
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = orderHash;
        uint64 expiration = uint64(block.timestamp + 100);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        bytes memory context = abi.encodePacked(considerationHash, _convertToBytesWithoutArrayLength(orderHashes));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );
        //console.logAddress(signer);

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, consideration);
        bytes4 selector = zone.validateOrder(params);
        assertEq(selector, bytes4(keccak256("validateOrder((bytes32,address,address,(uint8,address,uint256,uint256)[],(uint8,address,uint256,uint256,address)[],bytes,bytes32[],uint256,uint256,bytes32))")));
    }

    function testValidateOrderWithMultipleOrderHashes() public {
        console.logAddress(signer);
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 90);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        
        // Create array of order hashes
        bytes32[] memory orderHashes = new bytes32[](10);
        for (uint256 i = 0; i < 10; i++) {
            orderHashes[i] = keccak256(abi.encodePacked("order", i));
        }
        
        // Create context with consideration hash and order hashes
        bytes memory context = abi.encodePacked(considerationHash, _convertToBytesWithoutArrayLength(orderHashes));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, orderHashes, consideration);
        
        bytes4 selector = zone.validateOrder(params);
        assertEq(selector, bytes4(keccak256("validateOrder((bytes32,address,address,(uint8,address,uint256,uint256)[],(uint8,address,uint256,uint256,address)[],bytes,bytes32[],uint256,uint256,bytes32))")));
    }



    function testValidateOrderWithoutExtraData() public {
        bytes memory extraData = "";
        ZoneParameters memory params = _createZoneParameters(extraData);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.InvalidExtraData.selector, 
            "extraData is empty", params.orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWithInvalidExtraData() public {
        bytes memory extraData = abi.encodePacked(uint8(1), uint8(2), uint8(3));
        ZoneParameters memory params = _createZoneParameters(extraData);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.InvalidExtraData.selector, "extraData length must be at least 93 bytes", params.orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWithExpiredTimestamp() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp);
        bytes memory context = abi.encodePacked(keccak256("context"));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            signature,
            context
        );

        // Advance time past expiration
        uint64 timeNow = uint64(block.timestamp + 100);
        vm.warp(uint256(timeNow));

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignatureExpired.selector, timeNow, expiration, orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWithInvalidFulfiller() public {
        address invalidFulfiller = makeAddr("invalidFulfiller");
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 100);
        bytes memory context = abi.encodePacked(keccak256("context"));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            invalidFulfiller,
            expiration,
            signature,
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.InvalidFulfiller.selector, invalidFulfiller, fulfiller, orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWithNonZeroSIP6Version() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 100);
        bytes memory context = abi.encodePacked(keccak256("context"));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(1), // Non-zero SIP6 version
            fulfiller,
            expiration,
            signature,
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash);
        vm.expectRevert(abi.encodeWithSelector(SIP6EventsAndErrors.UnsupportedExtraDataVersion.selector, 1));
        zone.validateOrder(params);
    }

    function testValidateOrderWithNoContext() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 100);
        bytes memory context = "";

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            signature,
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.InvalidExtraData.selector, 
            "invalid context, expecting consideration hash followed by order hashes", params.orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWithWrongConsideration() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 100);
        bytes memory context = abi.encodePacked(keccak256("context"));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            signature,
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash);
        params.consideration = _createMockConsideration(10);
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SubstandardViolation.selector, 
            3, "invalid consideration hash", orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderRevertsAfterExpiration() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 90);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        bytes memory context = abi.encodePacked(considerationHash, orderHash);

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData);
        
        // First validate should succeed
        bytes4 selector = zone.validateOrder(params);
        assertEq(selector, bytes4(keccak256("validateOrder((bytes32,address,address,(uint8,address,uint256,uint256)[],(uint8,address,uint256,uint256,address)[],bytes,bytes32[],uint256,uint256,bytes32))")));

        // Advance time past expiration
        vm.warp(block.timestamp + 900);

        // Second validate should fail
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignatureExpired.selector, uint64(block.timestamp), expiration, orderHash));
        zone.validateOrder(params);
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
            fulfiller: fulfiller,
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


    function _signOrder(
        uint256 _signerPkey,
        bytes32 orderHash,
        uint64 expiration,
        bytes memory context
    ) internal view returns (bytes memory) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(ZONE_NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                address(zone)
            )
        );
        //console.logBytes32(domainSeparator);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SignedOrder(address fulfiller,uint64 expiration,bytes32 orderHash,bytes context)"),
                fulfiller,
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

    function _convertToBytesWithoutArrayLength(bytes32[] memory _orders) private view returns (bytes memory) {
        bytes memory data = abi.encodePacked(_orders);
        return this._stripArrayLength(data);
    }
    function _stripArrayLength(bytes calldata _data) external pure returns (bytes memory) {
        return _data[32:_data.length];
    }

} 