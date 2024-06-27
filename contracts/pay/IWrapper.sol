// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

interface IWrapper {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}