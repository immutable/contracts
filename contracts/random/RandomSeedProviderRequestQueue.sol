// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

/**
 * @notice Queue to be used with RandomSeedProvider
 * @dev    The contract is upgradeable.
 */
contract RandomSeedProviderRequestQueue {
    // Error thrown if a block is requested that isn't in the queue.
    error BlockNotFound(uint256 _blockNumber);

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

    /**
     * @notice Enqueue a block number if it is unique.
     * @param _blockNumber The number to add to the queue.
     */
    function enqueueIfUnique(uint256 _blockNumber) internal {
        // If the queue is not empty, check the latest value put into the tail of the queue.
        // If it is the same as the block number to be enqueued then there is nothing to do.
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        if (head != tail) {
            // slither-disable-next-line incorrect-equality
            if (outstandingRequests[tail] == _blockNumber) {
                return;
            }
        }
        tail++;
        outstandingRequests[tail] = _blockNumber;
        outstandingRequestsTail = tail;
    }

    /**
     * @notice Return the oldest value in the queue, without dequeuing it.
     * @return _blockNumber The next value that will be removed from the queue.
     */
    function peakNext() internal view returns (uint256 _blockNumber) {
        // If the queue empty
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        if (head == tail) {
            return 0;
        }
        // Note: Due to how dequeueBlockNumber works, there is no chance that
        // outstandingRequests[head + 1] will have been set to zero.
        return outstandingRequests[head + 1];
    }

    /**
     * @notice Locate a specific block number in the queue and remove it from the queue.
     * @param _blockNumber The block to dequeue.
     */
    function dequeueBlockNumber(uint256 _blockNumber) internal {
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;
        uint256 current = head;

        while (current != tail) {
            current++;
            // slither-disable-next-line incorrect-equality
            if (outstandingRequests[current] == _blockNumber) {
                // The entry for the block number has been found.
                // Remove the entry plus update the head or tail if the removed entry was
                // at the head or the tail of the queue.
                delete outstandingRequests[current];
                if (current == head + 1) {
                    head++;
                    // Oldest entry in the queue. Move the head until the entry is
                    // non-zero or the queue is empty.
                    // slither-disable-next-line incorrect-equality
                    while (outstandingRequests[head + 1] == 0 && head != tail) {
                        head++;
                    }
                    outstandingRequestsHead = head;
                } else if (current == tail) {
                    // Newest entry in the queue. Move the tail until the entry is
                    // non-zero. It is impossible to get to this point in the queue if
                    // the queue could be empty. That is, there must have been an element
                    // at head that wasn't the block number. As such, there is no need to
                    // check for an empty queue here.
                    tail--;
                    // slither-disable-next-line incorrect-equality
                    while (outstandingRequests[tail] == 0) {
                        tail--;
                    }
                    outstandingRequestsTail = tail;
                }
                return;
            }
        }
        revert BlockNotFound(_blockNumber);
    }

    /**
     * @notice Return an array of all block numbers in the queue prior to the current block.
     * @return _blockNumbers Array of block numbers. Is likely to be only partially filled.
     * @return _lengthUsed The number of entries in the _blockNumbers array used.
     */
    function dequeueHistoricBlockNumbers() internal returns (uint256[] memory _blockNumbers, uint256 _lengthUsed) {
        uint256 tail = outstandingRequestsTail;
        uint256 head = outstandingRequestsHead;

        _blockNumbers = new uint256[](tail - head);
        _lengthUsed = 0;

        while (head != tail) {
            uint256 blockNumber = outstandingRequests[head + 1];
            if (blockNumber >= block.number) {
                // The block is in the future, no more blocks to find.
                break;
            }
            head++;
            // slither-disable-next-line incorrect-equality
            if (blockNumber == 0) {
                // Skip if the block was consumed using dequeueBlockNumber.
                continue;
            }
            // Otherwise, add the block to the list.
            delete outstandingRequests[head];
            _blockNumbers[_lengthUsed++] = blockNumber;
        }
        outstandingRequestsHead = head;
    }

    /**
     * @notice Length of the queue.
     * @dev The returned length could include the current and future block numbers,
     *      and empty array entries for numbers previously using dequeueBlockNumber.
     * @return The length of the queue.
     */
    function queueLength() internal view returns (uint256) {
        return (outstandingRequestsTail - outstandingRequestsHead);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSeedProviderRequestQueue;
}
