// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @notice ERC 20 contract that wraps Open Zeppelin's ERC 20 contract.
 */
contract ImmutableERC20 is ERC20 {
    /**
     * @dev Delegate to Open Zeppelin's contract.
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
}
