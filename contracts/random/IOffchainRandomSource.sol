// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;


/**
 * @notice Off-chain random source adaptors must implement this interface.
 */
interface IOffchainRandomSource {
    // The random seed value is not yet available.
    error WaitForRandom();
    
    function requestOffchainRandom() external returns(uint256 _fulfilmentIndex);

    /**
     * @notice Fetch the latest off-chain generated random value.
     * @param _fulfillmentIndex Number previously given when requesting a ramdon value.
     * @return _randomValue The value generated off-chain.
     */
    function getOffchainRandom(uint256 _fulfillmentIndex) external view returns(bytes32 _randomValue);

    function isOffchainRandomReady(uint256 _fulfillmentIndex) external view returns(bool);
}