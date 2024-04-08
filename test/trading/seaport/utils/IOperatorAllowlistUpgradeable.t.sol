// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

/**
 * @notice Required interface of an OperatorAllowlist compliant contract
 */
interface IOperatorAllowlistUpgradeable {
    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `admin` address
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     */
    function initialize(address _roleAdmin, address _upgradeAdmin, address _registerarAdmin) external;

    /**
     * @notice Adds a list of multiple addresses to Allowlist
     * @param addressTargets the addresses to be added to the allowlist
     */
    function addAddressesToAllowlist(address[] calldata addressTargets) external;
}
