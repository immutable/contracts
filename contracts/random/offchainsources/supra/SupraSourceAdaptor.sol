// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {ISupraRouter} from "./ISupraRouter.sol";
import {SourceAdaptorBase} from "../SourceAdaptorBase.sol";

contract SupraSourceAdaptor is SourceAdaptorBase {
    error NotVrfContract();

    event SubscriptionChange(address _newSubscription);

    address public subscriptionAccount;

    constructor(
        address _roleAdmin,
        address _configAdmin,
        address _vrfCoordinator,
        address _subscription
    ) SourceAdaptorBase(_roleAdmin, _configAdmin, _vrfCoordinator) {
        subscriptionAccount = _subscription;
    }


    function setSubscription(address _subscription) external onlyRole(CONFIG_ADMIN_ROLE) {
        subscriptionAccount = _subscription;
        emit SubscriptionChange(subscriptionAccount);
    }


    function requestOffchainRandom() external returns (uint256 _requestId) {
        return
            ISupraRouter(vrfCoordinator).generateRequest(
                "fulfillRandomWords(uint256,uint256[])",
                uint8(NUM_WORDS),
                MIN_CONFIRMATIONS,
                subscriptionAccount
            );
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external {
        if (msg.sender != address(vrfCoordinator)) {
            revert NotVrfContract();
        }

        _fulfillRandomWords(_requestId, _randomWords);
    }
}
