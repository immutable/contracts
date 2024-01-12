// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RandomValues} from "contracts/random/RandomValues.sol";

contract MockGame is RandomValues {
    constructor(address _randomSeedProvider) RandomValues(_randomSeedProvider) {
    }

    function requestRandomValueCreation() external returns (uint256 _randomRequestId) {
        return _requestRandomValueCreation();
    }

    function fetchRandom(uint256 _randomRequestId) external returns(bytes32 _randomValue) {
        return _fetchRandom(_randomRequestId);
    }

    function fetchRandomValues(uint256 _randomRequestId, uint256 _size) external returns(bytes32[] memory _randomValues) {
        return _fetchRandomValues(_randomRequestId, _size);
    }

    function isRandomValueReady(uint256 _randomRequestId) external view returns(bool) {
        return _isRandomValueReady(_randomRequestId);
    }
}
