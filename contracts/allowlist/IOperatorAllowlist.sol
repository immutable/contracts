//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

/**
 * @dev Required interface of an OperatorAllowlist compliant contract
 */
interface IOperatorAllowlist {
    /// @dev Returns true if an address is Allowlisted false otherwise
    function isAllowlisted(address target) external view returns (bool);
}
