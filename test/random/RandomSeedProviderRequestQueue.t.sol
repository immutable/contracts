// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RandomSeedProviderRequestQueue} from "contracts/random/RandomSeedProviderRequestQueue.sol";

// Contract to make external the internal queue functions 
contract FakeRandomSeedProviderRequestQueue is RandomSeedProviderRequestQueue {
    constructor() {
        initializeRandomSeedProviderRequestQueue();
    }

    function enqueIfUnique1(uint256 _blockNumber) external {
        enqueueIfUnique(_blockNumber);
    }

    function peakNext1() external view returns (uint256) {
        return peakNext();
    }

    function dequeue1() external {
        dequeue();
    }

    function queueLength1() external view returns (uint256) {
        return queueLength();
    }
}


contract RandomSeedProviderRequestQueueTest is Test {
    FakeRandomSeedProviderRequestQueue public queue;

    function setUp() public virtual {
        queue = new FakeRandomSeedProviderRequestQueue();
    }

    function testInit() public {
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }

    function testEnqueue() public {
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
    }

    function testDequeue() public {
        queue.enqueIfUnique1(13);
        queue.dequeue1();
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }



    function testEnqueueDequeueMultiple() public {
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(17);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(19);
        assertEq(queue.queueLength1(), 3, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 17, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 19, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }

    function testEnqueueSame() public {
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(17);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(17);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(19);
        assertEq(queue.queueLength1(), 3, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(19);
        assertEq(queue.queueLength1(), 3, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 17, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 19, "peak");
        queue.enqueIfUnique1(19);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 19, "peak");
        queue.enqueIfUnique1(23);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 19, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 23, "peak");
        queue.dequeue1();
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }
}

