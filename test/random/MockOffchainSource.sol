// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOffchainRandomSource} from "contracts/random/IOffchainRandomSource.sol";


contract MockOffchainSource is IOffchainRandomSource {
    uint256 public nextIndex = 1000;
    bool public isReady;

    function setIsReady(bool _ready) external {
        isReady = _ready;
    }

    function requestOffchainRandom() external override(IOffchainRandomSource) returns(uint256 _fulfillmentIndex) {
        return nextIndex++;
    }

    function getOffchainRandom(uint256 _fulfillmentIndex) external view override(IOffchainRandomSource) returns(bytes32 _randomValue) {
        if (!isReady) {
            revert WaitForRandom();
        }
        return keccak256(abi.encodePacked(_fulfillmentIndex));
    }

    function isOffchainRandomReady(uint256 /* _fulfillmentIndex */) external view returns(bool) {
        return isReady;
    }


}
