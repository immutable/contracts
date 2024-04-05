// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

pragma solidity ^0.8.17;

import {ImmutableSeaport} from "../../../contracts/trading/seaport/ImmutableSeaport.sol";

contract ImmutableSeaportHarness is ImmutableSeaport {
    constructor(address conduitController, address owner) ImmutableSeaport(conduitController, owner) {}

    function exposed_deriveEIP712Digest(bytes32 domainSeparator, bytes32 orderHash) external pure returns (bytes32 value) {
        return _deriveEIP712Digest(domainSeparator, orderHash);
    }

    function exposed_domainSeparator() external view returns (bytes32) {
        return _domainSeparator();
    }
}
