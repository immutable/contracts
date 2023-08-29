//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import { AccessControlEnumerable, MintingAccessControl } from "./MintingAccessControl.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { OperatorAllowlistEnforced } from "../../../allowlist/OperatorAllowlistEnforced.sol";
import { ERC721HybridPermit } from "./ERC721HybridPermit.sol";
import { ERC721Hybrid } from "./ERC721Hybrid.sol";

abstract contract ImmutableERC721HybridBase is OperatorAllowlistEnforced, MintingAccessControl, ERC2981, ERC721HybridPermit {
    
    /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string public baseURI;

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address receiver_,
        uint96 feeNumerator_
    )ERC721HybridPermit(name_, symbol_) {
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
    )
        public
        view
        virtual
        override(ERC721HybridPermit, ERC2981, OperatorAllowlistEnforced, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Allows admin to set the base URI
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(string memory _contractURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    /// @dev Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721Hybrid) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Override of approve from {ERC721}, with added Allowlist approval validation
    function approve(address to, uint256 tokenId) public virtual override(ERC721Hybrid) validateApproval(to) {
        super.approve(to, tokenId);
    }

    /// @dev Override of internal transfer from {ERC721} function to include validation
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721HybridPermit) validateTransfer(from, to) {
        super._transfer(from, to, tokenId);
    }

    /// @dev Set the default royalty receiver address
    function setDefaultRoyaltyReceiver(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
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
