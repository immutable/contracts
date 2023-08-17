//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Allowlist Registry
import "./IRoyaltyAllowlist.sol";

// Access Control
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Errors
import {RoyaltyEnforcementErrors} from "../errors/Errors.sol";

abstract contract RoyaltyEnforced is
    AccessControlEnumerable,
    RoyaltyEnforcementErrors
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
    event RoyaltyAllowlistRegistryUpdated(
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
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyaltyAllowlistRegistry(
        address _royaltyAllowlist
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoyaltyAllowlistRegistry(_royaltyAllowlist);
    }

    function _setRoyaltyAllowlistRegistry(address _royaltyAllowlist) internal {
        if (
            !IERC165(_royaltyAllowlist).supportsInterface(
                type(IRoyaltyAllowlist).interfaceId
            )
        ) {
            revert RoyaltyEnforcementDoesNotImplementRequiredInterface();
        }

        emit RoyaltyAllowlistRegistryUpdated(
            address(royaltyAllowlist),
            _royaltyAllowlist
        );
        royaltyAllowlist = IRoyaltyAllowlist(_royaltyAllowlist);
    }

    modifier validateApproval(address targetApproval) {
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
        _;
    }

    /// @dev Internal function to validate whether the calling address is an EOA or Allowlisted
    modifier validateTransfer(address from, address to) {
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
        _;
    }
}
