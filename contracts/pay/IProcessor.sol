// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

interface IProcessor {

    function getQuote(address from, address to, uint256 exactAmountOut) external returns (uint256 quote);

}