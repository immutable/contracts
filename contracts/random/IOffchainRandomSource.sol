// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;


/**
 * @notice Off-chain random source adaptors must implement this interface.
 */
interface IOffchainRandomSource {

    function requestOffchainRandom() external returns(uint256 _fulfillmentIndex);

    /**
     * @notice Fetch the latest off-chain generated random value.
     * @param _fulfillmentIndex Number previously given when requesting a ramdon value.
     * @return _randomValue The value generated off-chain.
     */
    function getOffchainRandom(uint256 _fulfillmentIndex) external view returns(bytes32 _randomValue);
}