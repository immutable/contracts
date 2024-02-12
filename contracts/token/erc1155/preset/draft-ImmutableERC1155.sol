// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {ImmutableERC1155Base} from "../abstract/ImmutableERC1155Base.sol";

/**
 * @title draft-ImmutableERC1155
 * @author
 * @notice This contract is experimental and is in draft. It should be thoroughly reviewed before using.
 * It is possible for this contract to receive breaking changes, and backwards compatibility is not insured.
 */

contract ImmutableERC1155 is ImmutableERC1155Base {
    ///     =====   Constructor  =====

    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI`
     * Sets the royalty receiver and amount (this can not be changed once set)
     */
    constructor(
        address owner,
        string memory name_,
        string memory baseURI_,
        string memory contractURI_,
        address _operatorAllowlist,
        address _receiver,
        uint96 _feeNumerator
    ) ImmutableERC1155Base(owner, name_, baseURI_, contractURI_, _operatorAllowlist, _receiver, _feeNumerator) {}

    ///     =====   External functions  =====

    function safeMint(address to, uint256 id, uint256 value, bytes memory data) external onlyRole(MINTER_ROLE) {
        super._mint(to, id, value, data);
    }

    function safeMintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        super._mintBatch(to, ids, values, data);
    }
}
