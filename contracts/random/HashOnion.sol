// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

/**
 * @notice Hash onion revealer is used to reveal a sequence of values on-chain.
 * @dev    This will be used to add uncertainty to the chain in times of low utilisation 
 *         to ensure game players can not predict the block hash, and hence the 
 *         output of the on-chain random source.
 *         A hash onion is used so that the provider of the sequence can not change the 
 *         sequence to be reveals.
 */
contract HashOnion {
    /// @notice Indicate an incorrect preimage was presented.
    error IncorrectPreimage(bytes32 _preimage, bytes32 _commitment);

    /// @notice Hash commitment value. 
    bytes32 public commitment;

    /**
     * @notice Set the initial hash commitment.
     * @param _initialCommitment The initial commitment value.
     */
    constructor(bytes32 _initialCommitment) {
        commitment = _initialCommitment;
    }

    /**
     * @notice Reveal another layer of the hash onion.
     * @param _preimage The preimage of the commitment.
     */
    function reveal(bytes32 _preimage) external {
        bytes32 candidateCommitment = keccak256(abi.encodePacked(_preimage));
        if (candidateCommitment != commitment) {
            revert IncorrectPreimage(_preimage, commitment);
        }
        commitment = _preimage;
    }
}
