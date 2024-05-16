// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {HubOwner} from "../../common/HubOwner.sol";

/**
 * @notice ERC 20 contract that mints a fixed total supply of tokens when the contract
 *  is deployed.
 * @dev This contract has the concept of a hubOwner, called _hubOwner in the constructor.
 *  This account has no rights to execute any administrative actions within the contract,
 *  with the exception of renouncing their ownership.
 *  The Immutable Hub uses this function to help associate the ERC 20 contract
 *  with a specific Immutable Hub account.
 */

contract ImmutableERC20FixedSupplyNoBurnV2 is HubOwner, ERC20 {
    /**
     * @dev Mints `_totalSupply` number of token and transfers them to `_hubOwner`.
     * @param _roleAdmin The account that has the DEFAULT_ADMIN_ROLE.
     * @param _treasurer Initial owner of entire supply of all tokens.
     * @param _hubOwner The account associated with Immutable Hub.
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     * @param _totalSupply The fixed supply to be minted.
     */
    constructor(
        address _roleAdmin,
        address _treasurer,
        address _hubOwner,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) HubOwner(_roleAdmin, _hubOwner) ERC20(_name, _symbol) {
        _mint(_treasurer, _totalSupply);
    }
}
