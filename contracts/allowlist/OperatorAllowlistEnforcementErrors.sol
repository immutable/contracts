//SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

interface OperatorAllowlistEnforcementErrors {
    /// @dev Error thrown when the operatorAllowlist address does not implement the IOperatorAllowlist interface
    error AllowlistDoesNotImplementIOperatorAllowlist();

    /// @dev Error thrown when calling address is not OperatorAllowlist
    error CallerNotInAllowlist(address caller);

    /// @dev Error thrown when 'from' address is not OperatorAllowlist
    error TransferFromNotInAllowlist(address from);

    /// @dev Error thrown when 'to' address is not OperatorAllowlist
    error TransferToNotInAllowlist(address to);

    /// @dev Error thrown when approve target is not OperatorAllowlist
    error ApproveTargetNotInAllowlist(address target);

    /// @dev Error thrown when approve target is not OperatorAllowlist
    error ApproverNotInAllowlist(address approver);
}
