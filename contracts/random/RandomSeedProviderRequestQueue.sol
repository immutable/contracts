// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

/**
 * @notice Queue to be used with RandomSeedProvider
 * @dev    The contract is upgradeable.
 */
contract RandomSeedProviderRequestQueue {
    /// @notice Block numbers for which there have been requests to generate a seed value.
    mapping(uint256 index => uint256 blockNumber) private outstandingRequests;

    /// @notice Tail of the FIFO
    uint256 private outstandingRequestsTail;

    /// @notice Head of the FIFO
    uint256 private outstandingRequestsHead;

    function initializeRandomSeedProviderRequestQueue() internal {
        outstandingRequestsTail = 0;
        outstandingRequestsHead = 0;
    }

    function enqueueIfUnique(uint256 _blockNumber) internal {
        // If the queue is not empty, check the latest value put into the tail of the queue.
        // If it is the same as the block number to be enqueued then there is nothing to do.
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        if (head != tail) {
            if (outstandingRequests[tail] == _blockNumber) {
                return;
            }
        }
        tail++;
        outstandingRequests[tail] = _blockNumber;
        outstandingRequestsTail = tail;
    }

    function peakNext() internal view returns (uint256) {
        // If the queue empty
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        if (head == tail) {
            return 0;
        }
        return outstandingRequests[head + 1];
    }

    function dequeue() internal {
        // If the queue empty
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        if (head != tail) {
            head++;
            delete outstandingRequests[head];
            outstandingRequestsHead = head;
        }
    }

    function queueLength() internal view returns (uint256) {
        return (outstandingRequestsTail - outstandingRequestsHead);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSeedProviderRequestQueue;
}
