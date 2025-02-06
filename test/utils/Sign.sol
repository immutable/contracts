// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";

contract Sign {
    bytes32 private _DOMAIN_SEPARATOR;
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,bool approved,uint256 nonce,uint256 deadline)");

    constructor(bytes32 DOMAIN_SEPARATOR_) {
        _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR_;
    }

    function buildPermitDigest(address owner, address spender, bool approved, uint256 nonce, uint256 deadline)
        public
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, approved, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));
    }
}
