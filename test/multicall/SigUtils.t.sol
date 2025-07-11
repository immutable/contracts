// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {GuardedMulticaller2} from "../../contracts/multicall/GuardedMulticaller2.sol";

contract SigUtils {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal constant CALL_TYPEHASH = keccak256("Call(address target,string functionSignature,bytes data)");

    bytes32 internal constant MULTICALL_TYPEHASHV1 =
        keccak256(
            "Multicall(bytes32 ref,address[] targets,bytes[] data,uint256 deadline)"
        );

    bytes32 internal constant MULTICALL_TYPEHASHV2 =
        keccak256(
            "Multicall(bytes32 ref,Call[] calls,uint256 deadline)Call(address target,string functionSignature,bytes data)"
        );


    bytes32 private immutable cachedDomainSeparator;

    constructor(string memory _name, string memory _version, address _verifyingContract) {
        cachedDomainSeparator = keccak256(abi.encode(_TYPE_HASH, keccak256(bytes(_name)), keccak256(bytes(_version)), block.chainid, _verifyingContract));
    }

    function _hashCallArray(GuardedMulticaller2.Call[] calldata _calls) internal pure returns (bytes32) {
        bytes32[] memory hashedCallArr = new bytes32[](_calls.length);
        for (uint256 i = 0; i < _calls.length; i++) {
            hashedCallArr[i] = keccak256(
                abi.encode(CALL_TYPEHASH, _calls[i].target, _calls[i].functionSignature, _calls[i].data)
            );
        }
        return keccak256(abi.encode(hashedCallArr));
    }

    function hashTypedData(
        bytes32 _reference,
        GuardedMulticaller2.Call[] calldata _calls,
        uint256 _deadline
    ) public view returns (bytes32) {
        bytes32 digest = keccak256(abi.encode(MULTICALL_TYPEHASHV2, _reference, _hashCallArray(_calls), _deadline));
        return keccak256(abi.encodePacked("\x19\x01", cachedDomainSeparator, digest));
    }


    function hashTypedData(
        bytes32 _reference,
        address[] calldata _targets,
        bytes[] calldata _data,
        uint256 _deadline
    ) public view returns (bytes32) {
        bytes32 digest = keccak256(abi.encode(
            MULTICALL_TYPEHASHV1, 
            _reference, 
            keccak256(abi.encodePacked(_targets)), 
            hashBytesArray(_data), 
            _deadline));
        return keccak256(abi.encodePacked("\x19\x01", cachedDomainSeparator, digest));
    }

    function hashBytesArray(bytes[] memory _data) public pure returns (bytes32) {
        bytes32[] memory hashedBytesArr = new bytes32[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            hashedBytesArr[i] = keccak256(_data[i]);
        }
        return keccak256(abi.encodePacked(hashedBytesArr));
    }
}
