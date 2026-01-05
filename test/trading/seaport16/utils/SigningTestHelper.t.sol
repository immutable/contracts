// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import {Test} from "forge-std/Test.sol";

abstract contract SigningTestHelper is Test {
    function _sign(uint256 signerPrivateKey, bytes32 signatureDigest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, signatureDigest);
        return abi.encodePacked(r, s, v);
    }

    function _signCompact(uint256 signerPrivateKey, bytes32 signatureDigest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, signatureDigest);
        if (v != 27) {
            // then left-most bit of s has to be flipped to 1.
            s = s | bytes32(uint256(1) << 255);
        }
        return abi.encodePacked(r, s);
    }
}
