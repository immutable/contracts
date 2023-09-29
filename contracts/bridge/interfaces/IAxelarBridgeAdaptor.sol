// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAxelarBridgeAdaptorErrors {
    error ZeroAddresses();
    error InvalidChildChain();
    error NoGas();
    error CallerNotBridge();
    error InvalidArrayLengths();
}

interface IAxelarBridgeAdaptorEvents {
    event MapTokenAxelarMessage(string indexed childChain, string indexed childBridgeAdaptor, bytes indexed payload);
}
