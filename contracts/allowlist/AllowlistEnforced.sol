//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Allowlist Registry
import {IOperatorAllowlist} from "../allowlist/IOperatorAllowlist.sol";

// Access Control
import {AccessControlEnumerable, IERC165} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Errors
import {EnforcementErrors} from "../errors/Errors.sol";

abstract contract AllowlistEnforced is
    AccessControlEnumerable,
    EnforcementErrors
{
    ///     =====     Events         =====

    /// @dev Emitted whenever the transfer Allowlist registry is updated
    event OperatorAllowlistRegistryUpdated(
        address oldRegistry,
        address newRegistry
    );

    ///     =====   State Variables  =====

    /// @dev Interface that implements the `IOperatorAllowlist` interface
    IOperatorAllowlist public operatorAllowlist;

    ///     =====  External functions  =====

    /// @dev Returns the supported interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setOperatorAllowlistRegistry(
        address _operatorAllowlist
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOperatorAllowlistRegistry(_operatorAllowlist);
    }

    function _setOperatorAllowlistRegistry(
        address _operatorAllowlist
    ) internal {
        if (
            !IERC165(_operatorAllowlist).supportsInterface(
                type(IOperatorAllowlist).interfaceId
            )
        ) {
            revert AllowlistDoesNotImplementRequiredInterface();
        }

        emit OperatorAllowlistRegistryUpdated(
            address(operatorAllowlist),
            _operatorAllowlist
        );
        operatorAllowlist = IOperatorAllowlist(_operatorAllowlist);
    }

    modifier validateApproval(address targetApproval) {
        // Check for:
        // 1. approver is an EOA. Contract constructor is handled as transfers 'from' are blocked
        // 2. approver is address or bytecode is allowlisted
        if (
            msg.sender.code.length != 0 &&
            !operatorAllowlist.isAllowlisted(msg.sender)
        ) {
            revert ApproverNotInAllowlist(msg.sender);
        }

        // Check for:
        // 1. approval target is an EOA
        // 2. approval target address is Allowlisted or target address bytecode is Allowlisted
        if (
            targetApproval.code.length != 0 &&
            !operatorAllowlist.isAllowlisted(targetApproval)
        ) {
            revert ApproveTargetNotInAllowlist(targetApproval);
        }
        _;
    }

    /// @dev Internal function to validate whether the calling address is an EOA or Allowlisted
    modifier validateTransfer(address from, address to) {
        // Check for:
        // 1. caller is an EOA
        // 2. caller is Allowlisted or is the calling address bytecode is Allowlisted
        if (
            msg.sender != tx.origin && // solhint-disable-line avoid-tx-origin
            !operatorAllowlist.isAllowlisted(msg.sender)
        ) {
            revert CallerNotInAllowlist(msg.sender);
        }

        // Check for:
        // 1. from is an EOA
        // 2. from is Allowlisted or from address bytecode is Allowlisted
        if (from.code.length != 0 && !operatorAllowlist.isAllowlisted(from)) {
            revert TransferFromNotInAllowlist(from);
        }

        // Check for:
        // 1. to is an EOA
        // 2. to is Allowlisted or to address bytecode is Allowlisted
        if (to.code.length != 0 && !operatorAllowlist.isAllowlisted(to)) {
            revert TransferToNotInAllowlist(to);
        }
        _;
    }
}
