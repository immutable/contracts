// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

// Holds the creation code of the WalletProxy.yul used by smart contract wallet instances.
// Generate this bytecode using ./compileWalletProxyYul.sh
library Wallet {
    // This bytecode must precisely match that in tests/utils/helpers.ts
    bytes internal constant creationCode = hex"6054600f3d396034805130553df3fe63906111273d3560e01c14602b57363d3d373d3d3d3d369030545af43d82803e156027573d90f35b3d90fd5b30543d5260203df3";
}
