// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RandomValues} from "contracts/random/RandomValues.sol";

contract MockGame is RandomValues {
    constructor(address _randomSeedProvider) RandomValues(_randomSeedProvider) {}

    function requestRandomValueCreation(uint16 _size) external returns (uint256 _randomRequestId) {
        return _requestRandomValueCreation(_size);
    }

    function fetchRandomValues(uint256 _randomRequestId) external returns (bytes32[] memory _randomValues) {
        return _fetchRandomValues(_randomRequestId);
    }

    function isRandomValueReady(uint256 _randomRequestId) external view returns (RequestStatus) {
        return _isRandomValueReady(_randomRequestId);
    }
}
