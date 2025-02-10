// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControlEnumerable, MintingAccessControl} from "../../../access/MintingAccessControl.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorAllowlistEnforced} from "../../../allowlist/OperatorAllowlistEnforced.sol";
import {ERC721HybridPermitV2} from "./ERC721HybridPermitV2.sol";
import {ERC721HybridV2} from "./ERC721HybridV2.sol";

abstract contract ImmutableERC721HybridBaseV2 is
    ERC721HybridPermitV2,
    MintingAccessControl,
    OperatorAllowlistEnforced,
    ERC2981
{
    /// @notice Contract level metadata
    string public contractURI;

    /// @notice Common URIs for individual token URIs
    string public baseURI;

    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param receiver_ The address of the royalty receiver
     * @param feeNumerator_ The royalty fee numerator
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address receiver_,
        uint96 feeNumerator_
    ) ERC721HybridPermitV2(name_, symbol_) {
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _setDefaultRoyalty(receiver_, feeNumerator_);
        _setOperatorAllowlistRegistry(operatorAllowlist_);
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    /// @dev Returns the supported interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721HybridPermitV2, ERC2981, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns the baseURI of the collection
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Allows admin to set the base URI
     *  @param baseURI_ The base URI to set
     */
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /**
     * @notice sets the contract uri for the collection. Permissioned to only the admin role
     * @param _contractURI the new baseURI to set
     */
    function setContractURI(string memory _contractURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    /**
     * @inheritdoc ERC721
     * @dev Note it will validate the operator in the allowlist
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721, IERC721) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC721HybridV2
     * @dev Note it will validate the to address in the allowlist
     */
    function _approve(address to, uint256 tokenId) internal virtual override(ERC721HybridV2) validateApproval(to) {
        super._approve(to, tokenId);
    }

    /**
     * @inheritdoc ERC721HybridPermitV2
     * @dev Note it will validate the from and to address in the allowlist
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721HybridPermitV2) validateTransfer(from, to) {
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice Set the default royalty receiver address
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the an admin. See ERC2981 for more details on _setDefaultRoyalty
     */
    function setDefaultRoyaltyReceiver(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a specific tokenId
     *  @param tokenId the token to set the royalty for
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the a minter. See ERC2981 for more details on _setTokenRoyalty
     */
    function setNFTRoyaltyReceiver(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a list of tokenId
     *  @param tokenIds the list of tokens to set the royalty for
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the a minter. See ERC2981 for more details on _setTokenRoyalty
     */
    function setNFTRoyaltyReceiverBatch(
        uint256[] calldata tokenIds,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }
}
