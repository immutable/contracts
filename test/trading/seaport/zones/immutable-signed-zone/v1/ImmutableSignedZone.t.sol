// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ImmutableSignedZone} from "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v1/ImmutableSignedZone.sol";
import {ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ImmutableSignedZoneTest is Test {
    // using Strings for uint256;

    // ImmutableSignedZone public zone;
    // address public owner;
    // address public signer;
    // address public fulfiller;
    // uint256 public chainId;

    // function setUp() public {
    //     // Set up chain ID
    //     chainId = block.chainid;
        
    //     // Create test addresses
    //     owner = makeAddr("owner");
    //     signer = makeAddr("signer");
    //     fulfiller = makeAddr("fulfiller");

    //     // Deploy contract
    //     vm.startPrank(owner);
    //     zone = new ImmutableSignedZone("ImmutableSignedZone", "", "", owner);
    //     vm.stopPrank();
    // }

    // function test_DeployerBecomesOwner() public {
    //     assertEq(zone.owner(), owner);
    // }

    // function test_TransferOwnership() public {
    //     address newOwner = makeAddr("newOwner");
        
    //     vm.startPrank(owner);
    //     zone.transferOwnership(newOwner);
    //     vm.stopPrank();

    //     assertEq(zone.owner(), newOwner);
    // }

    // function testFail_NonOwnerCannotTransferOwnership() public {
    //     address newOwner = makeAddr("newOwner");
        
    //     vm.startPrank(signer);
    //     zone.transferOwnership(newOwner);
    //     vm.stopPrank();
    // }

    // function testFail_NonOwnerCannotAddSigner() public {
    //     vm.startPrank(signer);
    //     zone.addSigner(signer);
    //     vm.stopPrank();
    // }

    // function testFail_NonOwnerCannotRemoveSigner() public {
    //     vm.startPrank(signer);
    //     zone.removeSigner(signer);
    //     vm.stopPrank();
    // }

    // function test_OwnerCanAddAndRemoveActiveSigner() public {
    //     vm.startPrank(owner);
    //     zone.addSigner(signer);
    //     zone.removeSigner(signer);
    //     vm.stopPrank();
    // }

    // function testFail_CannotAddDeactivatedSigner() public {
    //     vm.startPrank(owner);
    //     zone.addSigner(signer);
    //     zone.removeSigner(signer);
    //     zone.addSigner(signer); // Should fail
    //     vm.stopPrank();
    // }

    // function testFail_AlreadyActiveSignerCannotBeAdded() public {
    //     vm.startPrank(owner);
    //     zone.addSigner(signer);
    //     zone.addSigner(signer); // Should fail
    //     vm.stopPrank();
    // }

    // function testFail_ValidateOrderWithoutExtraData() public {
    //     bytes memory extraData = "";
    //     ZoneParameters memory params = _createZoneParameters(extraData);
    //     zone.validateOrder(params);
    // }

    // function testFail_ValidateOrderWithInvalidExtraData() public {
    //     bytes memory extraData = abi.encodePacked(uint8(1), uint8(2), uint8(3));
    //     ZoneParameters memory params = _createZoneParameters(extraData);
    //     zone.validateOrder(params);
    // }

    // function testFail_ValidateOrderWithExpiredTimestamp() public {
    //     vm.startPrank(owner);
    //     zone.addSigner(signer);
    //     vm.stopPrank();

    //     bytes32 orderHash = keccak256("0x1234");
    //     uint64 expiration = uint64(block.timestamp);
    //     bytes memory context = abi.encodePacked(keccak256("context"));

    //     bytes memory signature = _signOrder(signer, orderHash, expiration, context);
    //     bytes memory extraData = abi.encodePacked(
    //         uint8(0), // SIP6 version
    //         fulfiller,
    //         expiration,
    //         signature,
    //         context
    //     );

    //     // Advance time past expiration
    //     vm.warp(block.timestamp + 100);

    //     ZoneParameters memory params = _createZoneParameters(extraData);
    //     zone.validateOrder(params);
    // }

    // // Helper functions
    // function _createZoneParameters(bytes memory extraData) internal view returns (ZoneParameters memory) {
    //     return ZoneParameters({
    //         orderHash: keccak256("0x1234"),
    //         fulfiller: fulfiller,
    //         offerer: address(0),
    //         offer: new ImmutableSignedZone.OfferItem[](0),
    //         consideration: new ImmutableSignedZone.ReceivedItem[](0),
    //         extraData: extraData,
    //         orderHashes: new bytes32[](0),
    //         startTime: 0,
    //         endTime: 0,
    //         zoneHash: bytes32(0)
    //     });
    // }

    // function _signOrder(
    //     address _signer,
    //     bytes32 orderHash,
    //     uint64 expiration,
    //     bytes memory context
    // ) internal view returns (bytes memory) {
    //     bytes32 domainSeparator = keccak256(
    //         abi.encode(
    //             keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    //             keccak256("ImmutableSignedZone"),
    //             keccak256("1"),
    //             chainId,
    //             address(zone)
    //         )
    //     );

    //     bytes32 structHash = keccak256(
    //         abi.encode(
    //             keccak256("SignedOrder(address fulfiller,uint64 expiration,bytes32 orderHash,bytes context)"),
    //             fulfiller,
    //             expiration,
    //             orderHash,
    //             keccak256(context)
    //         )
    //     );

    //     bytes32 digest = keccak256(
    //         abi.encodePacked("\x19\x01", domainSeparator, structHash)
    //     );

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(_signer)), digest);
    //     return abi.encodePacked(r, s, v);
    // }
} 