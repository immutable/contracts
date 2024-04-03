// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MintingAccessControl} from "../../../access/MintingAccessControl.sol";
import {IImmutableERC20Errors} from "../../../errors/ERC20Errors.sol";



/**
 * @notice ERC 20 contract that wraps Open Zeppelin's ERC 20 contract.
 * This contract has the concept of an owner, called _owner in the constructor.
 * This account has no rights to execute any administrative actions within the contract,
 *  with the exception of transferOwnership and role grants/revokes. This account is accessed via the owner() 
 *  function. The Immutable Hub uses this function to help associate the ERC 20 contract 
 *  with a specific Immutable Hub account.
 */
contract ImmutableERC20 is Ownable, ERC20Permit, MintingAccessControl {
    /**
     * @dev Delegate to Open Zeppelin's contract.
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     * @param _owner The account that owns the contract and is associated with Immutable Hub. 
     * @param minterRole The account that has the MINTER_ROLE.
     */
    constructor(string memory _name, string memory _symbol, address _owner, address minterRole) ERC20(_name, _symbol) ERC20Permit(_name) {
        _transferOwnership(_owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, minterRole);
    }

    /**
     * @dev Mints `amount` number of token and transfers them to the `to` address.
     * @param to the address to mint the tokens to.
     * @param amount  The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Burns `amount` number of tokens from the `from` address.
     * @param from the address to burn the tokens from.
     * @param amount the amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /** 
     * @notice Prevent calls to renounce ownership.
     */
    function renounceOwnership() public pure override {
        revert IImmutableERC20Errors.RenounceOwnershipNotAllowed();
    }
}
