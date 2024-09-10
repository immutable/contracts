// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.24;

import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";

/*
    OperatorAllowlist is an implementation of a Allowlist registry, storing addresses and bytecode
    which are allowed to be approved operators and execute transfers of interfacing token contracts (e.g. ERC721/ERC1155).
    The registry will be a deployed contract that tokens may interface with and point to.
    OperatorAllowlist is not designed to be upgradeable or extended.
*/

contract MockOperatorAllowlistUpgradeable is OperatorAllowlistUpgradeable {
    uint256 public mockInt;

    function setMockValue(uint256 val) public {
        mockInt = val;
    }
}
