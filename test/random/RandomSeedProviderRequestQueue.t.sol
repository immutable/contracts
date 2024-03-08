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

    function dequeueBlockNumber1(uint256 _blockNumber) external {
        dequeueBlockNumber(_blockNumber);
    }

    function dequeueHistoricBlockNumbers1() external returns (uint256[] memory _blockNumbers, uint256 _lengthUsed) {
        return dequeueHistoricBlockNumbers();
    }

    function queueLength1() external view returns (uint256) {
        return queueLength();
    }
}


contract RandomSeedProviderRequestQueueTest is Test {
    FakeRandomSeedProviderRequestQueue public queue;

    function setUp() public virtual {
        queue = new FakeRandomSeedProviderRequestQueue();
        vm.roll(block.number + 100);
    }

    function testInit() public {
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
        vm.expectRevert(abi.encodeWithSelector(RandomSeedProviderRequestQueue.BlockNotFound.selector, 7));
        queue.dequeueBlockNumber1(7);

        (uint256[] memory _blockNumbers, uint256 _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(_blockNumbers.length, 0, "length array");
        assertEq(_lengthUsed, 0, "len used");
    }

    function testEnqueue() public {
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
    }

    function testEnqueueSame() public {
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
        queue.enqueIfUnique1(13);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 13, "peak");
    }

    function testDequeueBlockNumberOnly() public {
        queue.enqueIfUnique1(13);
        queue.dequeueBlockNumber1(13);
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }

    function testDequeueBlockNumberFirst() public {
        queue.enqueIfUnique1(11);
        assertEq(queue.peakNext1(), 11, "peak");
        queue.enqueIfUnique1(13);
        assertEq(queue.peakNext1(), 11, "peak");
        queue.enqueIfUnique1(17);
        assertEq(queue.peakNext1(), 11, "peak");
        assertEq(queue.queueLength1(), 3, "length");
        queue.dequeueBlockNumber1(17);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 11, "peak");
    }

    function testDequeueBlockNumberLast() public {
        queue.enqueIfUnique1(11);
        assertEq(queue.peakNext1(), 11, "peak");
        queue.enqueIfUnique1(13);
        assertEq(queue.peakNext1(), 11, "peak");
        queue.enqueIfUnique1(17);
        assertEq(queue.peakNext1(), 11, "peak");
        assertEq(queue.queueLength1(), 3, "length");
        queue.dequeueBlockNumber1(11);
        assertEq(queue.queueLength1(), 2, "length");
        assertEq(queue.peakNext1(), 13, "peak");
    }

    function testDequeueBlockNumberMiddle() public {
        queue.enqueIfUnique1(11);
        queue.enqueIfUnique1(13);
        queue.enqueIfUnique1(17);
        queue.dequeueBlockNumber1(13);
        assertEq(queue.queueLength1(), 3, "length");
        assertEq(queue.peakNext1(), 11, "peak");
    }

    function testDequeueBlockNumberMultipleToFirst() public {
        queue.enqueIfUnique1(11);
        queue.enqueIfUnique1(13);
        queue.enqueIfUnique1(17);
        queue.dequeueBlockNumber1(13);
        queue.dequeueBlockNumber1(17);
        assertEq(queue.queueLength1(), 1, "length");
        assertEq(queue.peakNext1(), 11, "peak");
        queue.dequeueBlockNumber1(11);
        assertEq(queue.queueLength1(), 0, "length");
        assertEq(queue.peakNext1(), 0, "peak");
    }

    function testDequeueBlockNumberMultipleToLast() public {
        queue.enqueIfUnique1(11);
        queue.enqueIfUnique1(13);
        queue.enqueIfUnique1(17);
        queue.dequeueBlockNumber1(13);
        queue.dequeueBlockNumber1(11);
        assertEq(queue.queueLength1(), 1, "length1");
        assertEq(queue.peakNext1(), 17, "peak1");
        queue.dequeueBlockNumber1(17);
        assertEq(queue.queueLength1(), 0, "length2");
        assertEq(queue.peakNext1(), 0, "peak2");
    }

    function testDequeueHistoricBlockNumbersNoHistoricBlocks() public {
        queue.enqueIfUnique1(block.number);
        (uint256[] memory _blockNumbers, uint256 _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(_blockNumbers.length, 1, "length array");
        assertEq(_lengthUsed, 0, "len used");
        assertEq(queue.queueLength1(), 1, "length1");

        queue.enqueIfUnique1(block.number + 1);
        (_blockNumbers, _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(_blockNumbers.length, 2, "length array");
        assertEq(_lengthUsed, 0, "len used");
        assertEq(queue.queueLength1(), 2, "length2");
    }

    function testDequeueHistoricBlockNumbersOneBlock() public {
        queue.enqueIfUnique1(block.number - 1);
        (uint256[] memory _blockNumbers, uint256 _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(queue.queueLength1(), 0, "length1");
        assertEq(_blockNumbers.length, 1, "length array1");
        assertEq(_lengthUsed, 1, "len used1");
        assertEq(_blockNumbers[0], block.number - 1, "value1");

        queue.enqueIfUnique1(block.number - 1);
        queue.enqueIfUnique1(block.number);
        (_blockNumbers, _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(queue.queueLength1(), 1, "length1");
        assertEq(_blockNumbers.length, 2, "length array2");
        assertEq(_lengthUsed, 1, "len used2");
        assertEq(_blockNumbers[0], block.number - 1, "value2");
    }

    function testDequeueHistoricBlockNumbersMultipleBlocks() public {
        queue.enqueIfUnique1(block.number - 10);
        queue.enqueIfUnique1(block.number - 7);
        queue.enqueIfUnique1(block.number - 4);
        queue.enqueIfUnique1(block.number - 1);
        queue.enqueIfUnique1(block.number + 3);
        assertEq(queue.queueLength1(), 5, "length1");
        (uint256[] memory _blockNumbers, uint256 _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(queue.queueLength1(), 1, "length2");
        assertEq(_blockNumbers.length, 5, "length array1");
        assertEq(_lengthUsed, 4, "len used1");
        assertEq(_blockNumbers[0], block.number - 10, "value1");
        assertEq(_blockNumbers[1], block.number - 7, "value2");
        assertEq(_blockNumbers[2], block.number - 4, "value3");
        assertEq(_blockNumbers[3], block.number - 1, "value4");
    }

    function testDequeueHistoricBlockNumbersWithHoles() public {
        queue.enqueIfUnique1(block.number - 10);
        queue.enqueIfUnique1(block.number - 7);
        queue.enqueIfUnique1(block.number - 4);
        queue.enqueIfUnique1(block.number - 1);
        queue.enqueIfUnique1(block.number + 3);

        queue.dequeueBlockNumber1(block.number - 7);
        queue.dequeueBlockNumber1(block.number - 1);
        assertEq(queue.queueLength1(), 5, "length1");

        (uint256[] memory _blockNumbers, uint256 _lengthUsed) = queue.dequeueHistoricBlockNumbers1();
        assertEq(queue.queueLength1(), 1, "length2");
        assertEq(_blockNumbers.length, 5, "length array1");
        assertEq(_lengthUsed, 2, "len used1");
        assertEq(_blockNumbers[0], block.number - 10, "value1");
        assertEq(_blockNumbers[1], block.number - 4, "value2");
        assertEq(queue.peakNext1(), block.number + 3, "peak");
    }
}

