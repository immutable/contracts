// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {MintingAccessControl, AccessControl, IAccessControl} from "../../../access/MintingAccessControl.sol";
import {IImmutableERC20Errors} from "./Errors.sol";

/**
 * @notice ERC 20 contract that wraps Open Zeppelin's ERC 20 contract.
 * This contract has the concept of a hubOwner, called _hubOwner in the constructor.
 * This account has no rights to execute any administrative actions within the contract,
 *  with the exception of renouncing their ownership.
 *  The Immutable Hub uses this function to help associate the ERC 20 contract
 *  with a specific Immutable Hub account.
 */
contract ImmutableERC20MinterBurnerPermit is ERC20Capped, ERC20Burnable, ERC20Permit, MintingAccessControl {
    /// @notice Role to mint tokens
    bytes32 public constant HUB_OWNER_ROLE = bytes32("HUB_OWNER_ROLE");

    /**
     * @dev Delegate to Open Zeppelin's contract.
     * @param _roleAdmin The account that has the DEFAULT_ADMIN_ROLE.
     * @param _minterAdmin The account that has the MINTER_ROLE.
     * @param _hubOwner The account that owns the contract and is associated with Immutable Hub.
     * @param _name  Name of the token.
     * @param _symbol Token symbol.
     * @param _maxTokenSupply The maximum supply of the token.
     */
    constructor(
        address _roleAdmin,
        address _minterAdmin,
        address _hubOwner,
        string memory _name,
        string memory _symbol,
        uint256 _maxTokenSupply
    ) ERC20(_name, _symbol) ERC20Permit(_name) ERC20Capped(_maxTokenSupply) {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(HUB_OWNER_ROLE, _hubOwner);
        _grantRole(MINTER_ROLE, _minterAdmin);
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
     * @dev Renounces the role `role` from the calling account. Prevents the last hub owner and admin from
     * renouncing their role.
     * @param role The role to renounce.
     * @param account The account to renounce the role from.
     */
    function renounceRole(bytes32 role, address account) public override(AccessControl, IAccessControl) {
        if (getRoleMemberCount(role) == 1 && (role == HUB_OWNER_ROLE || role == DEFAULT_ADMIN_ROLE)) {
            revert IImmutableERC20Errors.RenounceOwnershipNotAllowed();
        }
        super.renounceRole(role, account);
    }

    /**
     * @dev Delegate to Open Zeppelin's ERC20Capped contract.
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }
}
