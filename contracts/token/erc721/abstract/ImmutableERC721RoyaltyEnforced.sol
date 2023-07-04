//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Allowlist Registry
import "../../../royalty-enforcement/IRoyaltyAllowlist.sol";

// Access Control
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/*
    ImmutableERC721RoyaltyEnforced is an abstract contract extending the ERC721 contract to enforce royalties.
    The contract has support to specify a allowlist registry and overrides transfers and approvals to enforce allow list validation.
*/

abstract contract ImmutableERC721RoyaltyEnforced is
    ERC721,
    AccessControlEnumerable
{
    ///     =====     Errors         =====

    /// @dev Error thrown when calling address is not Allowlisted
    error CallerNotInAllowlist(address caller);

    /// @dev Error thrown when 'from' address is not Allowlisted
    error TransferFromNotInAllowlist(address from);

    /// @dev Error thrown when 'to' address is not Allowlisted
    error TransferToNotInAllowlist(address to);

    /// @dev Error thrown when approve target is not Allowlisted
    error ApproveTargetNotInAllowlist(address target);

    /// @dev Error thrown when approve target is not Allowlisted
    error ApproverNotInAllowlist(address approver);

    ///     =====     Events         =====

    /// @dev Emitted whenever the transfer Allowlist registry is updated
    event RoyaltytAllowlistRegistryUpdated(
        address oldRegistry,
        address newRegistry
    );

    ///     =====   State Variables  =====

    /// @dev Interface that implements the `IRoyaltyAllowlist` interface
    IRoyaltyAllowlist public royaltyAllowlist;

    ///     =====  External functions  =====

    /// @dev Returns the supported interfaces
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Allows admin to set or update the royalty Allowlist registry
    function setRoyaltyAllowlistRegistry(
        address _royaltyAllowlist
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IERC165(_royaltyAllowlist).supportsInterface(
                type(IRoyaltyAllowlist).interfaceId
            ),
            "contract does not implement IRoyaltyAllowlist"
        );

        emit RoyaltytAllowlistRegistryUpdated(
            address(royaltyAllowlist),
            _royaltyAllowlist
        );
        royaltyAllowlist = IRoyaltyAllowlist(_royaltyAllowlist);
    }

    /// @dev Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _validateApproval(operator);
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Override of approve from {ERC721}, with added Allowlist approval validation
    function approve(address to, uint256 tokenId) public virtual override {
        _validateApproval(to);
        super.approve(to, tokenId);
    }

    /// @dev Internal function to validate whether approval targets are Allowlisted or EOA
    function _validateApproval(address targetApproval) internal view {
        // Only check if the registry is set
        if (address(royaltyAllowlist) != address(0)) {
            // Check for:
            // 1. approver is an EOA. Contract constructor is handled as transfers 'from' are blocked
            // 2. approver is address or bytecode is allowlisted
            if (
                msg.sender.code.length != 0 &&
                !royaltyAllowlist.isAllowlisted(msg.sender)
            ) {
                revert ApproverNotInAllowlist(msg.sender);
            }

            // Check for:
            // 1. approval target is an EOA
            // 2. approval target address is Allowlisted or target address bytecode is Allowlisted
            if (
                targetApproval.code.length != 0 &&
                !royaltyAllowlist.isAllowlisted(targetApproval)
            ) {
                revert ApproveTargetNotInAllowlist(targetApproval);
            }
        }
    }

    ///     =====  Internal functions  =====

    /// @dev Override of internal transfer from {ERC721} function to include validation
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        _validateTransfer(from, to);
        super._transfer(from, to, tokenId);
    }

    /// @dev Internal function to validate whether the calling address is an EOA or Allowlisted
    function _validateTransfer(address from, address to) internal view {
        // Only check if the registry is set
        if (address(royaltyAllowlist) != address(0)) {
            // Check for:
            // 1. caller is an EOA
            // 2. caller is Allowlisted or is the calling address bytecode is Allowlisted
            if (
                msg.sender != tx.origin &&
                !royaltyAllowlist.isAllowlisted(msg.sender)
            ) {
                revert CallerNotInAllowlist(msg.sender);
            }

            // Check for:
            // 1. from is an EOA
            // 2. from is Allowlisted or from address bytecode is Allowlisted
            if (
                from.code.length != 0 && !royaltyAllowlist.isAllowlisted(from)
            ) {
                revert TransferFromNotInAllowlist(from);
            }

            // Check for:
            // 1. to is an EOA
            // 2. to is Allowlisted or to address bytecode is Allowlisted
            if (to.code.length != 0 && !royaltyAllowlist.isAllowlisted(to)) {
                revert TransferToNotInAllowlist(to);
            }
        }
    }
}
