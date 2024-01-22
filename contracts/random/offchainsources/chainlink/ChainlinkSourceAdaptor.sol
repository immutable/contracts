// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {VRFConsumerBaseV2} from "./VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "./VRFCoordinatorV2Interface.sol";
import {SourceAdaptorBase} from "../SourceAdaptorBase.sol";
import {IOffchainRandomSource} from "../IOffchainRandomSource.sol";

/**
 * @notice Fetch random numbers from the Chainlink Verifiable Random
 * @notice Function (VRF).
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
contract ChainlinkSourceAdaptor is VRFConsumerBaseV2, SourceAdaptorBase {
    /// @notice Log config changes.
    event ConfigChanges( bytes32 _keyHash, uint64 _subId, uint32 _callbackGasLimit);

    /// @notice Relates to key that must sign the proof.
    bytes32 public keyHash;

    /// @notice Subscruption id.
    uint64 public subId;

    /// @notice Gas limit when executing the callback.
    uint32 public callbackGasLimit;

    /**
     * @param _roleAdmin Admin that can add and remove config admins.
     * @param _configAdmin Admin that can change the configuration.
     * @param _vrfCoordinator VRF coordinator contract address.
     * @param _keyHash Related to the signing / verification key.
     * @param _subId Subscription id.
     * @param _callbackGasLimit Gas limit to pass when calling the callback.
     */
    constructor(
        address _roleAdmin,
        address _configAdmin,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) SourceAdaptorBase(_roleAdmin, _configAdmin, _vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
    }

    /**
     * @notice Change the configuration.
     * @param _keyHash Related to the signing / verification key.
     * @param _subId Subscription id.
     * @param _callbackGasLimit Gas limit to pass when calling the callback.
     */
    function configureRequests(
        bytes32 _keyHash,
        uint64 _subId,
        uint32 _callbackGasLimit
    ) external onlyRole(CONFIG_ADMIN_ROLE) {
        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
        emit ConfigChanges(_keyHash, _subId, _callbackGasLimit);
    }

    /**
     * @inheritdoc IOffchainRandomSource
     */
    function requestOffchainRandom() external override(IOffchainRandomSource) returns (uint256 _requestId) {
        return
            VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
                keyHash,
                subId,
                MIN_CONFIRMATIONS,
                callbackGasLimit,
                NUM_WORDS
            );
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     */
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal virtual override(VRFConsumerBaseV2) {
        _fulfillRandomWords(_requestId, _randomWords);
    }
}
