// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {RandomSeedProvider} from "./RandomSeedProvider.sol";

/**
 * @notice Game contracts that need random numbers should extend this contract.
 * @dev This contract can be used with UPGRADEABLE or NON-UNGRADEABLE contracts.
 */
// slither-disable-start dead-code
abstract contract RandomValues {
    /// @notice Caused by requesting random values be generated, but then setting the size to zero.
    error RequestForNoRandomBytes();

    /// @notice Caused by fetch being called more than once for the same request id.
    error RandomValuesPreviouslyFetched();

    /// @notice Structure for a single random request.
    struct RandomRequest {
        // Id to match the random seed provider requests and responses.
        uint256 fulfilmentId;
        // Number of words requested. Retaining the size ensures the correct
        // number of words are returned.
        uint16 size;
        // Source of the random value: which off-chain, or the on-chain provider
        // will provide the random values. Retaining the source allows for upgrade
        // of sources inside the random seed provider contract.
        address source;
    }

    /// @notice Status of a random request
    enum RequestStatus {
        // The random value is being produced.
        IN_PROGRESS,
        // The random value is ready to be fetched.
        READY,
        // The random value either was never requested or has previously been fetched.
        ALREADY_FETCHED,
        // The random generation process failed. The random value should be re-requested.
        FAILED
    }

    // Address of random seed provider contract.
    // This value "immutable", and hence patched directly into bytecode when it is used.
    // There will only ever be one random seed provider per chain. Hence, this value
    // does not need to be changed.
    RandomSeedProvider public immutable randomSeedProvider;

    // Map of request id to random creation requests.
    mapping(uint256 requestId => RandomRequest request) private randCreationRequests;

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
     * @param _size The number of values to generate.
     * @return _randomRequestId A value that needs to be presented when fetching the random
     *      value with fetchRandom.
     */
    // slither-disable-next-line reentrancy-benign
    function _requestRandomValueCreation(uint16 _size) internal returns (uint256 _randomRequestId) {
        if (_size == 0) {
            revert RequestForNoRandomBytes();
        }

        uint256 randomFulfilmentIndex;
        address randomSource;
        (randomFulfilmentIndex, randomSource) = randomSeedProvider.requestRandomSeed();
        _randomRequestId = nextNonce++;
        randCreationRequests[_randomRequestId] = RandomRequest(randomFulfilmentIndex, _size, randomSource);
    }

    /**
     * @notice Fetch a set of random values that were requested using _requestRandomValueCreation.
     * @dev The values are customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.
     * @dev Note that the numbers can only be requested once. The numbers are deleted once fetched.
     *      This has been done to ensure games don't inadvertantly reuse the same random values
     *      in different contexts. Reusing random values could make games vulnerable to attacks
     *      where game players know the expected random values.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @return _randomValues An array of random values.
     */
    // slither-disable-next-line reentrancy-benign
    function _fetchRandomValues(uint256 _randomRequestId) internal returns (bytes32[] memory _randomValues) {
        RandomRequest memory request = randCreationRequests[_randomRequestId];
        if (request.size == 0) {
            revert RandomValuesPreviouslyFetched();
        }
        // Prevent random values from being re-fetched. This reduces the probability
        // that a game will mistakenly re-use the same random values for two purposes.
        delete randCreationRequests[_randomRequestId];

        // Request the random seed. If not enough time has elapsed yet, this call will revert.
        bytes32 randomSeed = randomSeedProvider.fulfilRandomSeedRequest(request.fulfilmentId, request.source);

        // Generate the personlised seed by combining:
        //  address(this): personalises the random seed to this game.
        //  msg.sender: personalises the random seed to the game player.
        //  _randomRequestId: Ensures that even if the game player has requested multiple random values,
        //    they will get a different value for each request.
        //  randomSeed: Value returned by the RandomManager.
        bytes32 seed = keccak256(abi.encodePacked(address(this), msg.sender, _randomRequestId, randomSeed));

        _randomValues = new bytes32[](request.size);
        for (uint256 i = 0; i < request.size; i++) {
            _randomValues[i] = keccak256(abi.encodePacked(seed, i));
        }
    }

    /**
     * @notice Check whether a set of random values are ready to be fetched
     * @dev If this function returns READY then it is safe to call _fetchRandom or _fetchRandomValues.
     * @param _randomRequestId The value returned by _requestRandomValueCreation.
     * @return RequestStatus indicates whether the random values are still be generated, are ready
     *      to be fetched, or whether they have already been fetched and are no longer available.
     */
    function _isRandomValueReady(uint256 _randomRequestId) internal view returns (RequestStatus) {
        RandomRequest memory request = randCreationRequests[_randomRequestId];
        if (request.size == 0) {
            return RequestStatus.ALREADY_FETCHED;
        }
        RandomSeedProvider.SeedRequestStatus status = randomSeedProvider.isRandomSeedReady(
            request.fulfilmentId,
            request.source
        );
        if (status == RandomSeedProvider.SeedRequestStatus.READY) {
            return RequestStatus.READY;
        }
        if (status == RandomSeedProvider.SeedRequestStatus.IN_PROGRESS) {
            return RequestStatus.IN_PROGRESS;
        }
        return RequestStatus.FAILED;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomValues;
}
// slither-disable-end dead-code
