//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an RoyaltyAllowlist compliant contract
 */
interface IRoyaltyAllowlist {
    /// @dev Returns true if an address is Allowlisted false otherwise
    function isAllowlisted(address target) external view returns (bool);
}
