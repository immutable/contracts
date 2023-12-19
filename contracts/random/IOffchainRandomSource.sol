// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;



interface IOffchainRandomSource {

    /**
     * @notice Fetch the latest off-chain generated random value.
     * @return _randomValue The value generated off-chain.
     * @return _index A number indicating how many random numbers have been previously generated.
     */
    function getOffchainRandom() external returns(bytes32 _randomValue, uint256 _index);
}