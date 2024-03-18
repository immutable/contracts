// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import { IReceiver } from "../IReceiver.sol";

contract SignatureValidatingReceiver is IReceiver {

    mapping(address => bool) approvedSigners;

    constructor() {
        
    }

    function onPaymentProcessed(Receipt memory receipt) external {

    }

}
