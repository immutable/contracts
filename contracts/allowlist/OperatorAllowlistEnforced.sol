// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

// Allowlist Registry
import {IOperatorAllowlist} from "./IOperatorAllowlist.sol";

// Access Control
import {AccessControlEnumerable, IERC165} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Errors
import {OperatorAllowlistEnforcementErrors} from "../errors/Errors.sol";

/*
    OperatorAllowlistEnforced is an abstract contract that token contracts can inherit in order to set the
    address of the OperatorAllowlist registry that it will interface with, so that the token contract may
    enable the restriction of approvals and transfers to allowlisted users.
    OperatorAllowlistEnforced is not designed to be upgradeable or extended.
*/

abstract contract OperatorAllowlistEnforced is AccessControlEnumerable, OperatorAllowlistEnforcementErrors {
    ///     =====   State Variables  =====

    /// @notice Interface that implements the `IOperatorAllowlist` interface
    IOperatorAllowlist public operatorAllowlist;

    ///     =====     Events         =====

    /// @notice Emitted whenever the transfer Allowlist registry is updated
    event OperatorAllowlistRegistryUpdated(address oldRegistry, address newRegistry);

    ///     =====     Modifiers      =====

    /**
     * @notice Internal function to validate an approval, according to whether the target is an EOA or Allowlisted
     * @param targetApproval the address of the approval target to be validated
     */
    modifier validateApproval(address targetApproval) {
        // Check for:
        // 1. approver is an EOA. Contract constructor is handled as transfers 'from' are blocked
        // 2. approver is address or bytecode is allowlisted
        if (msg.sender.code.length != 0 && !operatorAllowlist.isAllowlisted(msg.sender)) {
            revert ApproverNotInAllowlist(msg.sender);
        }

        // Check for:
        // 1. approval target is an EOA
        // 2. approval target address is Allowlisted or target address bytecode is Allowlisted
        if (targetApproval.code.length != 0 && !operatorAllowlist.isAllowlisted(targetApproval)) {
            revert ApproveTargetNotInAllowlist(targetApproval);
        }
        _;
    }

    /**
     * @notice Internal function to validate a transfer, according to whether the calling address,
     * from address and to address is an EOA or Allowlisted
     * @param from the address of the from target to be validated
     * @param to the address of the to target to be validated
     */
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

    ///     =====  External functions  =====

    /**
     * @notice Allows admin to set the operator allowlist the calling contract will interface with
     * @param _operatorAllowlist the address of the Allowlist registry
     */
    function setOperatorAllowlistRegistry(address _operatorAllowlist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOperatorAllowlistRegistry(_operatorAllowlist);
    }

    /**
     * @notice ERC-165 interface support
     * @param interfaceId The interface identifier, which is a 4-byte selector.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Internal function to set the operator allowlist the calling contract will interface with
     * @param _operatorAllowlist the address of the Allowlist registry
     */
    function _setOperatorAllowlistRegistry(address _operatorAllowlist) internal {
        if (!IERC165(_operatorAllowlist).supportsInterface(type(IOperatorAllowlist).interfaceId)) {
            revert AllowlistDoesNotImplementIOperatorAllowlist();
        }

        emit OperatorAllowlistRegistryUpdated(address(operatorAllowlist), _operatorAllowlist);
        operatorAllowlist = IOperatorAllowlist(_operatorAllowlist);
    }
}
