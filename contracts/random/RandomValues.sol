// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {RandomSeedProvider} from "./RandomSeedProvider.sol";



// TODO add doc: This contract should be extended by game companies, one per game. 

// TODO written so can be upgradeable
abstract contract RandomValues {
    mapping (uint256 => uint256) private randCreationRequests;
    uint256 private nextNonce;

    RandomSeedProvider public randomSeedProvider;


    constructor(address _randomSeedProvider) {
        randomSeedProvider = RandomSeedProvider(_randomSeedProvider);
    }


    /**
     * @notice Register a request to generate a random value. This function should be called
     *      when a game player has purchased an item that has a random value.
     * @param _securityLevel The number of random number generations to wait. A higher value provides
     *      better security. For most applications, a value of 1 or 2 is ideal. If the random number
     *      is for a high value transaction, choose a high number, for instance 3 or 4.
     * @return _randomRequestId A value that needs to be presented when fetching the random 
     *      value with fetchRandom.
     */
    function requestRandomValueCreation(uint256 _securityLevel) internal returns (uint256 _randomRequestId) {
        uint256 randomFulfillmentIndex = randomSeedProvider.requestRandom(_securityLevel);
        _randomRequestId = nextNonce++;
        randCreationRequests[_randomRequestId] = randomFulfillmentIndex;
    }


    /**
     * @notice Fetch a random value that was requested using requestRandomValueCreation.
     * @dev The value is customised to this game, the game player, and the request by the game player.
     *      This level of personalisation ensures that no two players end up with the same random value
     *      and no game player will have the same random value twice.   
     * @return _randomValue The index for the game contract to present to fetch the next random value.
     */
    function fetchRandom(uint256 _randomRequestId) internal returns(bytes32 _randomValue) {
        // Request the random seed. If not enough time has elapsed yet, this call will revert.
        bytes32 randomSeed = randomSeedProvider.getRandomSeed(randCreationRequests[_randomRequestId]);
        // Generate the random value by combining:
        //  address(this): personalises the random seed to this game.
        //  msg.sender: personalises the random seed to the game player.
        //  _randomRequestId: Ensures that even if the game player has requested multiple random values, 
        //    they will get a different value for each request.
        //  randomSeed: Value returned by the RandomManager.
        _randomValue = keccak256(abi.encodePacked(address(this), msg.sender, _randomRequestId, randomSeed));
    }

    // TODO storage gap
}