// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RandomSequences} from "contracts/random/RandomSequences.sol";

contract MockGameSeq is RandomSequences {
    constructor(address _randomSeedProvider) RandomSequences(_randomSeedProvider) {
    }

    function getNextRandom(uint256 _sequenceTypeId) external returns(bool _ready, bytes32 _randomValue) {
        return _getNextRandom(_sequenceTypeId);
    }


    function randomStatus(address _player, uint256 _sequenceTypeId) external view returns (RandomSequences.Status _status) {
        return _randomStatus(_player, _sequenceTypeId);
    }


    // Consume a random value and don't request another one.
    function hackConsumeRandomValue(uint256 _sequenceTypeId) external {
        // Assume sequenceTypeId is OK.
        // Assume request id has been set-up

        uint256 requestId = requestIds[msg.sender][_sequenceTypeId];
        requestId--;   // adjust id to start at 0, and not 1.

        // Fetch the random value and discard the output.
        _fetchRandomValues(requestId);
    }

}
