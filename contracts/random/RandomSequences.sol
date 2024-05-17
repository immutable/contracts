// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {RandomValues} from "./RandomValues.sol";

/**
 * @notice Game contracts that need random numbers should extend this contract.
 * @dev Note that game players will be able to know the next random value for any
 *      random sequence type. However, they will not be able to change the value.
 *      This type of random generation will be appropriate for many situations, but
 *      not all situations. The advantage of this type of generation is that
 *      it takes just one transaction per random number whereas RandomValues.sol
 *      takes two transactions per random number.
 * @dev This contract can be used with UPGRADEABLE or NON-UNGRADEABLE contracts.
 *
 * This contract utilises the concept of sequences of random numbers. Games should
 * define all of the types of random number generation they plan to use. They should
 * assign a separate sequence type id to each type of random number generation. For
 * example, imagine a game had three uses for random numbers: determining the results
 * of opening an Armour Loot Box, determining the results of opening a Weapon Loot
 * Box, and determining the value of a Participation Bonus. Each of these types
 * of random numbers needs to have a separate Sequence Type Id: for instance 1, 2,
 * and 3.
 *
 * Using a separate sequence type id for each type of random action is important as
 * game players can exploit sequences that are used for two or more actions. For
 * example, imagine that all three types of random values described above used the
 * same sequence. A game player could predict the next random value. If this was not
 * going to yeild a good random result for the Armour or the Weapon Loot Boxes, they
 * would do the action in the game to ensure the number was used for the
 * Participation Bonus. They could do this repeatedly, only utilising the random values
 * for Loot Boxes that were advantageous to them.
 *
 * Using a separate sequence type id for each class of random means that even though
 * the game player knows the outcome opening a Loot Box ahead of time, they can't
 * alter the outcome. They could choose to never open the Loot Box, or leave the game
 * and create a new player profile. However, within their current player profile, they
 * could not change the outcome.
 *
 * An example of when this type of random number generation isn't appropriate is
 * when there is a shared activity. For example, drawing a prize that multiple people
 * can simultaneously bid on. Using this sequence type random generation process,
 * where savvy game players could predict the random output, and would thus have
 * an advantage over less savvy players is not appropriate. In this case, use the
 * RandomValues.sol directly.
 *
 */
// slither-disable-start dead-code
abstract contract RandomSequences is RandomValues {
    // @notice Error thrown if sequence number is out of range.
    error InvalidSequenceTypeId(uint256 _sequenceTypeId);

    // @notice The requested value has been fetched previously.
    // The only way for the value to have been previously fetched is if the game contract
    // has directly fetched the random value, which should not happen as this contract
    // should be the only entity interacting with the random values provider.
    error RandomValuePreviouslyFetched();

    // @notice Status value type returned by _randomStatus.
    enum Status {
        // @notice the sequence id is out of range.
        SEQUENCE_ID_INVALID,
        // @notice There has been no call to _getNextRandom for this player and sequence id.
        NO_INITIAL_REQUEST,
        // @notice The random value is ready to be returned.
        READY,
        // @notice The random value is being generated, but is not ready yet.
        IN_PROGRESS,
        // @notice The application needs to call _getNextRandom to trigger another request.
        RETRY,
        // @notice The requested value has been fetched previously.
        // The only way for the value to have been previously fetched is if the game contract
        // has directly fetched the random value, which should not happen as this contract
        // should be the only entity interacting with the random values provider.
        PREVIOUSLY_FETCHED
    }

    // @notice The maximum sequence id.
    // @dev This is an limit value here is an artificial limit. If a game had more than 100,000
    // paralllel sequences of random values, then this number could be set to a higher value.
    // The rationale for 100,000 is that this appears to be more random sequences than any game
    // will need. The reason for secifying a number is so that the fix sized storage array data
    // structure can be used.
    // slither-disable-next-line too-many-digits
    uint256 private constant MAX_SEQUENCE = 100000;

    // @notice Random request ids per player and sequence.
    mapping(address player => uint256[MAX_SEQUENCE] reqIds) internal requestIds;

    /**
     * @notice Set the address of the random seed provider.
     * @param _randomSeedProvider Address of random seed provider.
     */
    constructor(address _randomSeedProvider) RandomValues(_randomSeedProvider) {}

    /**
     * @notice Fetch the next random value and request another random value.
     * @dev Note that game players who can analyse contract state will be able to predict the
     *      next random value in a sequence. They will not, however, be able to change the
     *      value.
     * @param _sequenceTypeId The sequence of random numbers to fetch from.
     * @return _ready True when the returned randomValue is valid.
     * @return _randomValue The generated random value.
     */
    // slither-disable-next-line reentrancy-no-eth
    function _getNextRandom(uint256 _sequenceTypeId) internal returns (bool _ready, bytes32 _randomValue) {
        if (_sequenceTypeId >= MAX_SEQUENCE) {
            revert InvalidSequenceTypeId(_sequenceTypeId);
        }

        // If there has been no request so far, then request now.
        uint256 requestId = requestIds[msg.sender][_sequenceTypeId];
        if (requestId == 0) {
            _requestNext(_sequenceTypeId);
            return (false, bytes32(0));
        }
        requestId--; // adjust id to start at 0, and not 1.

        // Check to see if it is ready.
        RequestStatus status = _isRandomValueReady(requestId);
        if (status == RequestStatus.IN_PROGRESS) {
            return (false, bytes32(0));
        }
        if (status == RequestStatus.FAILED) {
            // Re-request the random.
            _requestNext(_sequenceTypeId);
            return (false, bytes32(0));
        }
        if (status == RequestStatus.ALREADY_FETCHED) {
            // The only way for the value to have been previously fetched is if the game contract
            // has directly fetched the random value, which should not happen as this contract
            // should be the only entity interacting with the random values provider.
            revert RandomValuePreviouslyFetched();
        }

        // Fetch the random value and submit a request for another
        bytes32[] memory randomValues = _fetchRandomValues(requestId);
        _requestNext(_sequenceTypeId);
        return (true, randomValues[0]);
    }

    /**
     * @notice Request a new random value be generated.
     * @param _sequenceTypeId The sequence of random numbers to fetch from.
     */
    // slither-disable-next-line reentrancy-benign
    function _requestNext(uint256 _sequenceTypeId) private {
        uint256 requestId = _requestRandomValueCreation(1);
        requestId++; // have request ids start at 1, and not 0.
        requestIds[msg.sender][_sequenceTypeId] = requestId;
    }

    /**
     * @notice Check whether a random value us ready to be fetched.
     * @dev If this function returns READY then it is safe to call _getNextRandom.
     * @param _player The player that the random number is being fetched for.
     * @param _sequenceTypeId The sequence of random numbers to fetch from.
     * @return _status The state of the random number generation process.
     */
    function _randomStatus(address _player, uint256 _sequenceTypeId) internal view returns (Status _status) {
        if (_sequenceTypeId >= MAX_SEQUENCE) {
            return Status.SEQUENCE_ID_INVALID;
        }
        uint256 requestId = requestIds[_player][_sequenceTypeId];
        if (requestId == 0) {
            return Status.NO_INITIAL_REQUEST;
        }
        requestId--;
        RequestStatus status = _isRandomValueReady(requestId);
        if (status == RequestStatus.READY) {
            return Status.READY;
        }
        if (status == RequestStatus.IN_PROGRESS) {
            return Status.IN_PROGRESS;
        }
        if (status == RequestStatus.FAILED) {
            return Status.RETRY;
        }

        // The only way for the value to have been previously fetched is if the game contract
        // has directly fetched the random value, which should not happen as this contract
        // should be the only entity interacting with the random values provider.
        return Status.PREVIOUSLY_FETCHED;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSequences;
}
// slither-disable-end dead-code
