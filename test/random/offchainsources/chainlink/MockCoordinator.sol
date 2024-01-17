// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "../../../../contracts/random/offchainsources/chainlink/VRFCoordinatorV2Interface.sol";
import {ChainlinkSourceAdaptor} from "../../../../contracts/random/offchainsources/chainlink/ChainlinkSourceAdaptor.sol";

contract MockCoordinator is VRFCoordinatorV2Interface {
    event RequestId(uint256 _requestId);

    ChainlinkSourceAdaptor public adaptor;
    uint256 public nextIndex = 1000;


    function setAdaptor(address _adaptor) external {
        adaptor = ChainlinkSourceAdaptor(_adaptor);
    }

    function sendFulfill(uint256 _requestId) external {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = _requestId + 1;
        adaptor.rawFulfillRandomWords(_requestId, randomWords);
    }


    function requestRandomWords(bytes32,uint64,uint16,uint32,uint32) external returns (uint256 requestId) {
        requestId = nextIndex++;
        emit RequestId(requestId);
    }


    // Unused functions

    function getRequestConfig() external pure returns (uint16, uint32, bytes32[] memory) {
        bytes32[] memory a;
        return (uint16(0), uint32(0), a);
    }

    function createSubscription() external pure returns (uint64 subId) {
        return (uint64(0));
    }

    function getSubscription(uint64) external pure 
        returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) {
        return (uint96(0), uint64(0), address(0), consumers);
    }

    function requestSubscriptionOwnerTransfer(uint64, address) external {}
    function acceptSubscriptionOwnerTransfer(uint64) external {}
    function addConsumer(uint64, address) external {}
    function removeConsumer(uint64, address) external{}
    function cancelSubscription(uint64, address) external{}
    function pendingRequestExists(uint64) external pure returns (bool) {
        return false;
    }
}

