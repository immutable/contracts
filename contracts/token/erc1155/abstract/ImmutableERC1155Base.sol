// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "../../../token/erc1155/abstract/ERC1155Permit.Sol";

// Allowlist
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../../allowlist/OperatorAllowlistEnforced.sol";

// Utils
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract ImmutableERC1155Base is OperatorAllowlistEnforced, ERC1155Permit, ERC2981 {
    /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string private _baseURI;

    /// @dev Only MINTER_ROLE can invoke permissioned mint.
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /// @dev mapping of each token id supply
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
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
    ) ERC1155Permit(name_, baseURI_) {
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _setDefaultRoyalty(_receiver, _feeNumerator);
        _setOperatorAllowlistRegistry(_operatorAllowlist);
        contractURI = contractURI_;
        _baseURI = baseURI_;
    }

    /**
     * @notice sets the default royalty receiver
     * @param receiver The address of the royalty receiver
     * @param feeNumerator The royalty fee numerator
     */
    function setDefaultRoyaltyReceiver(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a specific tokenId
     * @param tokenId The token identifier to set the royalty receiver for.
     * @param receiver The address of the royalty receiver
     * @param feeNumerator The royalty fee numerator
     */
    function setNFTRoyaltyReceiver(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a list of tokenIDs
     * @param tokenIds The token identifiers to set the royalty receiver for.
     * @param receiver The address of the royalty receiver
     * @param feeNumerator The royalty fee numerator
     */
    function setNFTRoyaltyReceiverBatch(
        uint256[] calldata tokenIds,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }

    /**
     * @notice Grants minter role to the user
     * @param user The address to grant the MINTER_ROLE to
     */
    function grantMinterRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /**
     * @notice Allows admin to revoke `MINTER_ROLE` role from `user`
     * @param user The address to revoke the MINTER_ROLE from
     */
    function revokeMinterRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }

    /**
     * @notice Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
     * @param operator The address to approve as an operator for the caller.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC1155) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Sets `_baseURI` as the `_baseURI` for all tokens
     * @param baseURI_ The base URI for all tokens
     */
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(baseURI_);
        _baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = contractURI_;
    }

    /**
     * @notice Total value of tokens in with a given id.
     * @param id The token identifier to retrieve the total supply for.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @notice Indicates whether any token exist with a given id, or not.
     * @param id The token identifier to check for existence.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @notice Overrides supportsInterface from ERC1155, ERC2981, and OperatorAllowlistEnforced
     * @param interfaceId The interface identifier, which is a 4-byte selector.
     * @return True if the contract implements `interfaceId` and the call doesn't revert, otherwise false.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Permit, ERC2981, OperatorAllowlistEnforced) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID if the uri contains `\{id\}`.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @notice See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID if the uri contains `\{id\}`.
     *
     * returns the baseURI of the contract. This is the same as baseURI()
     * This is done to unify the uri and baseuri variables for Immutable's metadata
     * indexing
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _baseURI;
    }

    /**
     * @notice Returns the addresses which have DEFAULT_ADMIN_ROLE
     * @return admins The addresses which have DEFAULT_ADMIN_ROLE
     */
    function getAdmins() public view returns (address[] memory) {
        uint256 adminCount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        address[] memory admins = new address[](adminCount);
        for (uint256 i; i < adminCount; i++) {
            admins[i] = getRoleMember(DEFAULT_ADMIN_ROLE, i);
        }
        return admins;
    }

    /**
     * @notice See Openzepplin ERC1155._beforeTokenTransfer.
     * @param operator The address performing the transfer.
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param ids The token identifiers to transfer.
     * @param amounts The amounts to transfer per token id.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @notice Override of _safeTransferFrom from {ERC1155}, with added Allowlist transfer validation
     * @param from The current owner of the token.
     * @param to The new owner.
     * @param id The token identifier to transfer.
     * @param value The amount to transfer.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal override validateTransfer(from, to) {
        super._safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @notice Override of _safeBatchTransferFrom from {ERC1155}, with added Allowlist transfer validation
     * @param from The current owner of the token.
     * @param to The new owner.
     * @param ids The token identifiers to transfer.
     * @param values The amounts to transfer per token id.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal override validateTransfer(from, to) {
        super._safeBatchTransferFrom(from, to, ids, values, data);
    }
}
