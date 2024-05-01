// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IImmutableERC20Errors} from "./Errors.sol";


/**
 * @notice This contract is now deprecated in favour of ImmutableERC20FixedSupplyNoBurnV2.sol.
 * 
 * @notice ERC 20 contract that mints a fixed total supply of tokens when the contract 
 *  is deployed.
 * @dev This contract has the concept of an owner, called _hubOwner in the constructor. 
 *  This account has no rights to execute any administrative actions within the contract,
 *  with the exception of transferOwnership. This account is accessed via the owner() 
 *  function. The Immutable Hub uses this function to help associate the ERC 20 contract 
 *  with a specific Immutable Hub account.
 */
contract ImmutableERC20FixedSupplyNoBurn is Ownable, ERC20 {
    // Report an error if renounceOwnership is called.
    error RenounceOwnershipNotAllowed();

    /**
     * @dev Mints `_totalSupply` number of token and transfers them to `_owner`.
     *
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     * @param _totalSupply Supply of the token.
     * @param _treasurer Initial owner of entire supply of all tokens.
     * @param _hubOwner The account associated with Immutable Hub. 
     */
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _treasurer, address _hubOwner) ERC20(_name, _symbol) {
        _mint(_treasurer, _totalSupply);
        _transferOwnership(_hubOwner);
    }

    /** 
     * @notice Prevent calls to renounce ownership.
     */
    function renounceOwnership() public pure override {
        revert IImmutableERC20Errors.RenounceOwnershipNotAllowed();
    }
}
