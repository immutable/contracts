// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {RandomSeedProvider} from "./RandomSeedProvider.sol";

/**
 * @notice Game contracts that need random numbers should extend this contract.
 * @dev This contract can be used with UPGRADEABLE or NON-UNGRADEABLE contracts.
 */
abstract contract RandomValues {
    // Address of random seed provider contract.
    // This value "immutable", and hence patched directly into bytecode when it is used.
    // There will only ever be one random seed provider per chain. Hence, this value
    // does not need to be changed.
    RandomSeedProvider public immutable randomSeedProvider;

    // Map of request id to fulfilment id.
    mapping(uint256 requestId => uint256 fulfilmentId) private randCreationRequests;
    // Map of request id to random source. Retaining the source allows for upgrade
    // of sources inside the random seed provider contract.
    mapping(uint256 requestId => address randomSource) private randCreationRequestsSource;

    // Each request has a unique request id. The id is the current value
    // of nextNonce. nextNonce is incremented for each request.
    uint256 private nextNonce;

    /**
     * @notice Set the address of the random seed provider.
     * @param _randomSeedProvider Address of random seed provider.
     */
    constructor(address _randomSeedProvider) {
        randomSeedProvider = RandomSeedProvider(_randomSeedProvider);
    }

    /**
     * @notice Register a request to generate a random value. This function should be called
     *      when a game player has purchased an item the value of which is based on a random value.
     * @return _randomRequestId A value that needs to be presented when fetching the random
     *      value with fetchRandom.
     */
    function _requestRandomValueCreation() internal returns (uint256 _randomRequestId) {
        uint256 randomFulfilmentIndex;
        address randomSource;
        (randomFulfilmentIndex, randomSource) = randomSeedProvider.requestRandomSeed();
        _randomRequestId = nextNonce++;
        randCreationRequests[_randomRequestId] = randomFulfilmentIndex;
        randCreationRequestsSource[_randomRequestId] = randomSource;
    }

    /**
     * @notice Fetch a random value that was requested using _requestRandomValueCreation.
     * @dev The value is customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @return _randomValue The random number that the game can use.
     */
    function _fetchRandom(uint256 _randomRequestId) internal returns (bytes32 _randomValue) {
        return _fetchPersonalisedSeed(_randomRequestId);
    }

    /**
     * @notice Fetch a set of random values that were requested using _requestRandomValueCreation.
     * @dev The values are customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @param _size The size of the array to return.
     * @return _randomValues An array of random values derived from a single random value.
     */
    function _fetchRandomValues(
        uint256 _randomRequestId,
        uint256 _size
    ) internal returns (bytes32[] memory _randomValues) {
        bytes32 seed = _fetchPersonalisedSeed(_randomRequestId);

        _randomValues = new bytes32[](_size);
        for (uint256 i = 0; i < _size; i++) {
            _randomValues[i] = keccak256(abi.encodePacked(seed, i + 1));
        }
    }

    /**
     * @notice Check whether a random value is ready.
     * @dev If this function returns true then it is safe to call _fetchRandom or _fetchRandomValues.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @return True when the random value is ready to be retrieved.
     */
    function _isRandomValueReady(uint256 _randomRequestId) internal view returns (bool) {
        return
            randomSeedProvider.isRandomSeedReady(
                randCreationRequests[_randomRequestId],
                randCreationRequestsSource[_randomRequestId]
            );
    }

    /**
     * @notice Fetch a seed from which random values can be generated, based on _requestRandomValueCreation.
     * @dev The value is customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @return _seed The seed value to base random numbers on.
     */
    function _fetchPersonalisedSeed(uint256 _randomRequestId) private returns (bytes32 _seed) {
        // Request the random seed. If not enough time has elapsed yet, this call will revert.
        bytes32 randomSeed = randomSeedProvider.getRandomSeed(
            randCreationRequests[_randomRequestId],
            randCreationRequestsSource[_randomRequestId]
        );
        // Generate the personlised seed by combining:
        //  address(this): personalises the random seed to this game.
        //  msg.sender: personalises the random seed to the game player.
        //  _randomRequestId: Ensures that even if the game player has requested multiple random values,
        //    they will get a different value for each request.
        //  randomSeed: Value returned by the RandomManager.
        _seed = keccak256(abi.encodePacked(address(this), msg.sender, _randomRequestId, randomSeed));
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomValues;
}
