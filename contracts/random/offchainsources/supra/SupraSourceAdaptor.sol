// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import "./ISupraRouter.sol";
import "../SourceAdaptorBase.sol";


contract SupraSourceAdaptor is SourceAdaptorBase {
    address public subscriptionAccount;

    constructor(address _roleAdmin, address _configAdmin, address _vrfCoordinator, address _subscription) 
                SourceAdaptorBase(_roleAdmin, _configAdmin, _vrfCoordinator) {
        subscriptionAccount = _subscription;
    }

    function requestOffchainRandom() external returns(uint256 _requestId) {
        return ISupraRouter(vrfCoordinator).generateRequest("fulfillRandomWords(uint256,uint256[])", 
            uint8(NUM_WORDS), MIN_CONFIRMATIONS, 123, subscriptionAccount);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external {
        _fulfillRandomWords(_requestId, _randomWords);
    }
}