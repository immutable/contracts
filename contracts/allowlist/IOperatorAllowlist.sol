// Copyright Immutable Pty Ltd 2018 - 2026
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <=0.8.27;

/**
 * @notice Required interface of an OperatorAllowlist compliant contract
 */
interface IOperatorAllowlist {
    /**
     * @notice Returns true if an address is Allowlisted false otherwise
     *  @param target the address to be checked against the Allowlist
     */
    function isAllowlisted(address target) external view returns (bool);
}
