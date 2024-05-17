// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

import {SIP7EventsAndErrors} from "./SIP7EventsAndErrors.sol";

/**
 * @title SIP7Interface
 * @author ryanio, Immutable
 * @notice ImmutableSignedZone is an implementation of SIP-7 that requires orders
 *         to be signed by an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *
 */
interface SIP7Interface is SIP7EventsAndErrors {
    /**
     * @dev The struct for storing signer info.
     */
    struct SignerInfo {
        /// @dev If the signer is currently active.
        bool active;
        /// @dev If the signer has been active before.
        bool previouslyActive;
    }

    /**
     * @notice Add a new signer to the zone.
     *
     * @param signer The new signer address to add.
     */
    function addSigner(address signer) external;

    /**
     * @notice Remove an active signer from the zone.
     *
     * @param signer The signer address to remove.
     */
    function removeSigner(address signer) external;

    /**
     * @notice Update the API endpoint returned by this zone.
     *
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(string calldata newApiEndpoint) external;

    /**
     * @notice Update the documentation URI returned by this zone.
     *
     * @param newDocumentationURI The new documentation URI.
     */
    function updateDocumentationURI(string calldata newDocumentationURI) external;

    /**
     * @notice Returns signing information about the zone.
     *
     * @return domainSeparator The domain separator used for signing.
     * @return apiEndpoint     The API endpoint to get signatures for orders
     *                         using this zone.
     */
    function sip7Information()
        external
        view
        returns (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        );
}
