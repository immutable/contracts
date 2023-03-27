//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Allowlist Registry
import "../../royalty-enforcement/IRoyaltyAllowlist.sol";

/*
    TODO: top level contract comment
*/

abstract contract ImmutableERC721RoyaltyEnforced is
    ERC721
{
    ///     =====     Errors         =====

    /// @dev Error thrown when calling address is not Allowlisted
    error CallerNotInAllowlist(address caller);

    /// @dev Error thrown when approve target is not Allowlisted
    error ApproveTargetNotInAllowlist(address target);

    ///     =====     Events         =====

    /// @dev Emitted whenever the transfer Allowlist registry is updated
    event RoyaltytAllowlistRegistryUpdated(address oldRegistry, address newRegistry);

    ///     =====   State Variables  =====

    /// @dev Interface that implements the `IRoyaltyAllowlist` interface
    IRoyaltyAllowlist public royaltyAllowlist;

    /// @dev Allows admin to set or update the royalty Allowlist registry
    function setRoyaltyAllowlistRegistry(address _royaltyAllowlist) public virtual {
        require(IERC165(_royaltyAllowlist).supportsInterface(type(IRoyaltyAllowlist).interfaceId), "contract does not implement IRoyaltyAllowlist");

        emit RoyaltytAllowlistRegistryUpdated(address(royaltyAllowlist), _royaltyAllowlist);
        royaltyAllowlist = IRoyaltyAllowlist(_royaltyAllowlist);
    }

    /// @dev Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
    function setApprovalForAll(address operator, bool approved) public virtual override {
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
        if(address(royaltyAllowlist).code.length > 0) {
             // Check for:
            // 1. approval target is an EOA
            // 2. approval target address is Allowlisted or target address bytecode is Allowlisted
            if (targetApproval.code.length == 0 || royaltyAllowlist.isAllowlisted(targetApproval)){
                return;
            }
            revert ApproveTargetNotInAllowlist(targetApproval);
        }
    }

    /// @dev Override of internal transfer from {ERC721} function to include validation
       function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        _validateTransfer();
        super._transfer(from, to, tokenId);
    }

    /// @dev Internal function to validate whether the calling address is an EOA or Allowlisted
    function _validateTransfer() internal view {
        // Only check if the registry is set
        if (address(royaltyAllowlist).code.length > 0) {
            // Check for:
            // 1. caller is an EOA
            // 2. caller is Allowlisted or is the calling address bytecode is Allowlisted
            if(msg.sender == tx.origin || royaltyAllowlist.isAllowlisted(msg.sender))
            {
                return;
            }
            revert CallerNotInAllowlist(msg.sender);
        }
    }

}
