//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import { AccessControlEnumerable, ERC721AccessControl } from "./ERC721AccessControl.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { RoyaltyEnforced } from "../../../royalty-enforcement/RoyaltyEnforced.sol";

abstract contract ERC721Royalty is RoyaltyEnforced, ERC721AccessControl, ERC2981, ERC721 {

    constructor(
        address royaltyAllowlist_,
        address receiver_,
        uint96 feeNumerator_
    ) {
        // Initialize state variables
        _setDefaultRoyalty(receiver_, feeNumerator_);
        setRoyaltyAllowlistRegistry(royaltyAllowlist_);
    }

    /// @dev Returns the supported interfaces
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC2981, RoyaltyEnforced, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Override of approve from {ERC721}, with added Allowlist approval validation
    function approve(
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) validateApproval(to) {
        super.approve(to, tokenId);
    }

    /// @dev Override of internal transfer from {ERC721} function to include validation
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) validateTransfer(from, to) {
        super._transfer(from, to, tokenId);
    }

    /// @dev Set the default royalty receiver address
    function setDefaultRoyaltyReceiver(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev Set the royalty receiver address for a specific tokenId
    function setNFTRoyaltyReceiver(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev Set the royalty receiver address for a list of tokenIDs
    function setNFTRoyaltyReceiverBatch(
        uint256[] calldata tokenIds,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }

}
