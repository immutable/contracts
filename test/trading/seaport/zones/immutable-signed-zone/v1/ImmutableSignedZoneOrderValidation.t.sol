// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ImmutableSeaportTestHelper} from "../../../ImmutableSeaportTestHelper.t.sol";
import {ImmutableSignedZone} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {SIP7EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP7EventsAndErrors.sol";
import {SIP6EventsAndErrors} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/interfaces/SIP6EventsAndErrors.sol";
import {ZoneParameters, ReceivedItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";


contract ImmutableSignedZoneOrderValidationTest is Test, ImmutableSeaportTestHelper {
    ImmutableSignedZone public zone;
    address public owner;
    address public signer;
    uint256 public signerPkey;
    address public fulfiller;
    uint256 public chainId;

    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        (signer, signerPkey) = makeAddrAndKey("signer");
        fulfiller = makeAddr("fulfiller");

        // Deploy contract
        vm.startPrank(owner);
        zone = new ImmutableSignedZone(ZONE_NAME, "", "", owner);
        zone.addSigner(signer);
        vm.stopPrank();

        _setFulfillerAndZone(fulfiller, address(zone));
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

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, consideration);
        bytes4 selector = zone.validateOrder(params);
        assertEq(selector, bytes4(keccak256("validateOrder((bytes32,address,address,(uint8,address,uint256,uint256)[],(uint8,address,uint256,uint256,address)[],bytes,bytes32[],uint256,uint256,bytes32))")));
    }

    function testValidateOrderWithMultipleOrderHashes() public {
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

    function testValidateOrderWithPartialOrderHashes() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 90);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        
        // Create array of order hashes
        bytes32[] memory orderHashes = new bytes32[](10);
        for (uint256 i = 0; i < 10; i++) {
            orderHashes[i] = keccak256(abi.encodePacked("order", i));
        }
        
        // Create partial array of order hashes (first 2)
        bytes32[] memory partialOrderHashes = new bytes32[](2);
        partialOrderHashes[0] = orderHashes[0];
        partialOrderHashes[1] = orderHashes[1];
        
        // Create context with consideration hash and partial order hashes
        bytes memory context = abi.encodePacked(considerationHash, _convertToBytesWithoutArrayLength(partialOrderHashes));

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

    function testValidateOrderWhenNotAllExpectedOrdersAreZoneParameters() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 90);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        
        // Create array of order hashes
        bytes32[] memory orderHashes = new bytes32[](10);
        for (uint256 i = 0; i < 10; i++) {
            orderHashes[i] = keccak256(abi.encodePacked("order", i));
        }
        
        // Create context with consideration hash and full order hashes
        bytes memory context = abi.encodePacked(considerationHash, _convertToBytesWithoutArrayLength(orderHashes));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );

        // Create partial array of order hashes (first 2)
        bytes32[] memory partialOrderHashes = new bytes32[](2);
        partialOrderHashes[0] = orderHashes[0];
        partialOrderHashes[1] = orderHashes[1];

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, partialOrderHashes, consideration);
        
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SubstandardViolation.selector, 
            4, "invalid order hashes", orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderWhenNotAllExpectedOrdersAreZoneParametersVariation() public {
        bytes32 orderHash = keccak256("0x1234");
        uint64 expiration = uint64(block.timestamp + 90);
        ReceivedItem[] memory consideration = _createMockConsideration(10);
        bytes32 considerationHash = this._deriveConsiderationHash(consideration);
        
        // Create array of order hashes
        bytes32[] memory orderHashes = new bytes32[](10);
        for (uint256 i = 0; i < 10; i++) {
            orderHashes[i] = keccak256(abi.encodePacked("order", i));
        }
        
        // Create context with consideration hash and full order hashes
        bytes memory context = abi.encodePacked(considerationHash, _convertToBytesWithoutArrayLength(orderHashes));

        bytes memory signature = _signOrder(signerPkey, orderHash, expiration, context);
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );

        // Create array with first 2 order hashes and 2 random hashes
        bytes32[] memory mixedOrderHashes = new bytes32[](4);
        mixedOrderHashes[0] = orderHashes[0];
        mixedOrderHashes[1] = orderHashes[1];
        mixedOrderHashes[2] = keccak256("0x55");
        mixedOrderHashes[3] = keccak256("0x66");

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, mixedOrderHashes, consideration);
        
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SubstandardViolation.selector, 
            4, "invalid order hashes", orderHash));
        zone.validateOrder(params);
    }

    function testValidateOrderRevertsWithIncorrectlySignedSignature() public {
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

        // Sign with wrong signer
        (address wrongSigner, uint256 wrongSignerPkey) = makeAddrAndKey("wrongSigner");
        bytes memory signature = _signOrder(wrongSignerPkey, orderHash, expiration, context);
        
        bytes memory extraData = abi.encodePacked(
            uint8(0), // SIP6 version
            fulfiller,
            expiration,
            this._convertSignatureToEIP2098(signature),
            context
        );

        ZoneParameters memory params = _createZoneParameters(extraData, orderHash, orderHashes, consideration);
        
        vm.expectRevert(abi.encodeWithSelector(SIP7EventsAndErrors.SignerNotActive.selector, wrongSigner));
        zone.validateOrder(params);
    }
} 