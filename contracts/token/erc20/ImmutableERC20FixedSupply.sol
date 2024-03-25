// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @notice ERC 20 contract that mints a fixed total supply of tokens when the contract 
 *  is deployed.
 */
contract ImmutableERC20FixedSupply is ERC20 {
    /**
     * @dev Mints `_totalSupply` number of token and transfers them to `_owner`.
     *
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     * @param _totalSupply Supply of the token.
     * @param _owner Initial owner of entire supply of all tokens.
     */
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _owner) ERC20(_name, _symbol) {
        _mint(_owner, _totalSupply);
    }
}
