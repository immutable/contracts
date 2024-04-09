// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

/**
 * @notice SIP7EventsAndErrors contains errors and events
 *         related to zone interaction as specified in the SIP-7.
 */
interface SIP7EventsAndErrors {
    /**
     * @dev Emit an event when a new signer is added.
     */
    event SignerAdded(address signer);

    /**
     * @dev Emit an event when a signer is removed.
     */
    event SignerRemoved(address signer);

    /**
     * @dev Revert with an error if trying to add a signer that is
     *      already active.
     */
    error SignerAlreadyActive(address signer);

    /**
     * @dev Revert with an error if trying to remove a signer that is
     *      not active.
     */
    error SignerNotActive(address signer);

    /**
     * @dev Revert with an error if a new signer is the zero address.
     */
    error SignerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if a removed signer is trying to be
     *      reauthorized.
     */
    error SignerCannotBeReauthorized(address signer);

    /**
     * @dev Revert with an error when the signature has expired.
     */
    error SignatureExpired(uint256 currentTimestamp, uint256 expiration, bytes32 orderHash);

    /**
     * @dev Revert with an error if the fulfiller does not match.
     */
    error InvalidFulfiller(address expectedFulfiller, address actualFulfiller, bytes32 orderHash);

    /**
     * @dev Revert with an error if supplied order extraData is invalid
     *      or improperly formatted.
     */
    error InvalidExtraData(string reason, bytes32 orderHash);

    /**
     * @dev Revert with an error if a substandard validation fails.
     *      This is a custom error that is not part of the SIP-7 spec.
     */
    error SubstandardViolation(uint256 substandardId, string reason, bytes32 orderHash);

    /**
     * @dev Revert with an error if substandard 3 validation fails.
     *      This is a custom error that is not part of the SIP-7 spec.
     */
    error Substandard3Violation(bytes32 orderHash);

    /**
     * @dev Revert with an error if substandard 4 validation fails.
     *      This is a custom error that is not part of the SIP-7 spec.
     */
    error Substandard4Violation(bytes32[] actualOrderHashes, bytes32[] expectedOrderHashes, bytes32 orderHash);

    /**
     * @dev Revert with an error if substandard 6 validation fails.
     *      This is a custom error that is not part of the SIP-7 spec.
     */
    error Substandard6Violation(uint256 actualSpentItemAmount, uint256 originalSpentItemAmount, bytes32 orderHash);
}
