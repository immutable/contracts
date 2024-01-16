// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "../SourceAdaptorBase.sol";

/**
 * @notice Fetch random numbers from the Chainlink Verifiable Random 
 * @notice Function (VRF).
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
contract ChainlinkSourceAdaptor is VRFConsumerBaseV2, SourceAdaptorBase {

    bytes32 public keyHash;
    uint64 public subId;
    uint32 public callbackGasLimit;


    constructor(address _roleAdmin, address _configAdmin, address _vrfCoordinator, bytes32 _keyHash, 
                uint64 _subId, uint32 _callbackGasLimit) 
                VRFConsumerBaseV2(_vrfCoordinator) 
                SourceAdaptorBase(_roleAdmin, _configAdmin, _vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
    }

    function configureRequests(bytes32 _keyHash, uint64 _subId, uint32 _callbackGasLimit) external onlyRole(CONFIG_ADMIN_ROLE) {
        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
    }

    function requestOffchainRandom() external returns(uint256 _requestId) {
        return VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(keyHash, subId, MIN_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }


// Call back
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
        _fulfillRandomWords(_requestId, _randomWords);
    }
}