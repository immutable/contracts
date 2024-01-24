// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {ISupraRouter} from "./ISupraRouter.sol";
import {SourceAdaptorBase} from "../SourceAdaptorBase.sol";
import {IOffchainRandomSource} from "../IOffchainRandomSource.sol";

/**
 * @notice Fetch random numbers from the Supra Verifiable Random
 * @notice Function (VRF).
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
contract SupraSourceAdaptor is SourceAdaptorBase {
    /// @notice Error if a contract other than the Supra Router attempts to supply random values.
    error NotVrfContract();

    /// @notice Subscription address has changed.
    event SubscriptionChange(address _newSubscription);

    /// @notice Subscription access.
    address public subscriptionAccount;

    /**
     * @param _roleAdmin Admin that can add and remove config admins.
     * @param _configAdmin Admin that can change the configuration.
     * @param _vrfCoordinator VRF coordinator contract address.
     * @param _subscription Subscription account.
     */
    constructor(
        address _roleAdmin,
        address _configAdmin,
        address _vrfCoordinator,
        address _subscription
    ) SourceAdaptorBase(_roleAdmin, _configAdmin, _vrfCoordinator) {
        subscriptionAccount = _subscription;
    }

    /**
     * @notice Change the subscription account address.
     * @param _subscription The address of the new subscription.
     */
    function setSubscription(address _subscription) external onlyRole(CONFIG_ADMIN_ROLE) {
        subscriptionAccount = _subscription;
        emit SubscriptionChange(subscriptionAccount);
    }

    /**
     * @inheritdoc IOffchainRandomSource
     */
    function requestOffchainRandom() external override(IOffchainRandomSource) returns (uint256 _requestId) {
        return
            ISupraRouter(vrfCoordinator).generateRequest(
                "fulfillRandomWords(uint256,uint256[])",
                uint8(NUM_WORDS),
                MIN_CONFIRMATIONS,
                subscriptionAccount
            );
    }

    /**
     * @notice Callback called when random words are returned by the VRF.
     * @param _requestId is the fulfilment index.
     * @param _randomWords are the random values from the VRF.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external {
        if (msg.sender != address(vrfCoordinator)) {
            revert NotVrfContract();
        }

        _fulfillRandomWords(_requestId, _randomWords);
    }
}
