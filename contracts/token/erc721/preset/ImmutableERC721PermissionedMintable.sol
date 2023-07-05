//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "../abstract/ImmutableERC721Base.sol";

/*
    ImmutableERC721PermissionedMintable is a preset contract that inherits from ImmutableERC721Base
    and overrides the mint function to provide a permissioned mint function. The contract adds a
    MINTER_ROLE that allows members of the role to access the `mint` function.
*/

contract ImmutableERC721PermissionedMintable is ImmutableERC721Base {
    ///     =====   State Variables  =====

    /// @dev Only MINTER_ROLE can invoke permissioned mint.
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner_` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
     * Sets the `reciever` and `feeNumerator`
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address _receiver,
        uint96 _feeNumerator
    )
        ImmutableERC721Base(
            owner_,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            _receiver,
            _feeNumerator
        )
    {}

    ///     =====  External functions  =====

    /// @dev Allows minter to mint `amount` to `to`
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        for (uint256 i; i < amount; i++) {
            _mintNextToken(to);
        }
    }

    /// @dev Allows admin grant `user` `MINTER` role
    function grantMinterRole(
        address user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev Allows admin to revoke `MINTER_ROLE` role from `user`
    function revokeMinterRole(
        address user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }
}
