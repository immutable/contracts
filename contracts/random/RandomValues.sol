// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {RandomSeedProvider} from "./RandomSeedProvider.sol";

/**
 * @notice Game contracts that need random numbers should extend this contract. 
 * @dev This variant of the contract has been used with UPGRADEABLE or NON-UNGRADEABLE contracts.
 */
abstract contract RandomValues {
    RandomSeedProvider public immutable randomSeedProvider;

    mapping (uint256 => uint256) private randCreationRequests;
    mapping (uint256 => RandomSeedProvider.GenerationMethodology) private randCreationRequestsMethod;

    uint256 private nextNonce;

    constructor(address _randomSeedProvider) {
        randomSeedProvider = RandomSeedProvider(_randomSeedProvider);
    }
 
    /**
     * @notice Register a request to generate a random value. This function should be called
     *      when a game player has purchased an item that has a random value.
     * @return _randomRequestId A value that needs to be presented when fetching the random 
     *      value with fetchRandom.
     */
    function _requestRandomValueCreation() internal returns (uint256 _randomRequestId) {
        uint256 randomFulfillmentIndex;
        RandomSeedProvider.GenerationMethodology method;
        (randomFulfillmentIndex, method) = randomSeedProvider.requestRandomSeed();
        _randomRequestId = nextNonce++;
        randCreationRequests[_randomRequestId] = randomFulfillmentIndex;
        randCreationRequestsMethod[_randomRequestId] = method;
    }


    /**
     * @notice Fetch a random value that was requested using requestRandomValueCreation.
     * @dev The value is customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.   
     * @return _randomValue The index for the game contract to present to fetch the next random value.
     */
    function _fetchRandom(uint256 _randomRequestId) internal returns(bytes32 _randomValue) {
        // Request the random seed. If not enough time has elapsed yet, this call will revert.
        bytes32 randomSeed = randomSeedProvider.getRandomSeed(
            randCreationRequests[_randomRequestId], randCreationRequestsMethod[_randomRequestId]);
        // Generate the random value by combining:
        //  address(this): personalises the random seed to this game.
        //  msg.sender: personalises the random seed to the game player.
        //  _randomRequestId: Ensures that even if the game player has requested multiple random values, 
        //    they will get a different value for each request.
        //  randomSeed: Value returned by the RandomManager.
        _randomValue = keccak256(abi.encodePacked(address(this), msg.sender, _randomRequestId, randomSeed));
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomValues;
}