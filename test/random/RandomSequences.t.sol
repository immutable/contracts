// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockGameSeq,RandomSequences} from "./MockGameSeq.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";



contract BaseRandomSequencesTest is Test {
    address public constant ONCHAIN = address(0);
    uint256 public constant STANDARD_ONCHAIN_DELAY = 2;

    ERC1967Proxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;

    MockGameSeq public game1;

    address public roleAdmin;
    address public randomAdmin;
    address public upgradeAdmin;

    function setUp() public virtual {
        roleAdmin = makeAddr("roleAdmin");
        randomAdmin = makeAddr("randomAdmin");
        upgradeAdmin = makeAddr("upgradeAdmin");

        impl = new RandomSeedProvider();
        proxy = new ERC1967Proxy(address(impl), 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, upgradeAdmin, false));
        randomSeedProvider = RandomSeedProvider(address(proxy));

        game1 = new MockGameSeq(address(randomSeedProvider));
    }
}

contract UninitializedRandomSequencesTest is BaseRandomSequencesTest {
    function testInit() public {
        assertEq(address(game1.randomSeedProvider()), address(randomSeedProvider), "randomSeedProvider");
        assertEq(uint256(game1.randomStatus(address(0), 0)), uint256(RandomSequences.Status.NO_INITIAL_REQUEST), "Should not be ready");
    }
}

contract RandomSequencesGetRandomTest is BaseRandomSequencesTest {
    function testGetInvalidSequenceTypeId() public {
        vm.expectRevert(abi.encodeWithSelector(RandomSequences.InvalidSequenceTypeId.selector, 100000));
        game1.getNextRandom(100000);
    }

    function testGetNoExistingRequest() public {
        (bool ready, ) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");
    }

    function testGetInProgress() public {
        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);
        // Second call in the same block will return that the random value is not ready yet.
        (bool ready, ) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");
    }

    function testGetAlreadyFetched() public {
        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        game1.hackConsumeRandomValue(0);

        vm.expectRevert(abi.encodeWithSelector(RandomSequences.RandomValuePreviouslyFetched.selector));
        game1.getNextRandom(0);
    }

    function testGetRandom() public {
        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        // One block later the random number should be ready
        (bool ready, bytes32 val) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        assertNotEq(val, 0, "val is 0");
    }

    function testGetRandomMultiple() public {
        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (bool ready0, bytes32 val0) = game1.getNextRandom(0);
        assertTrue(ready0, "Should be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (bool ready1, bytes32 val1) = game1.getNextRandom(0);
        assertTrue(ready1, "Should be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (bool ready2, bytes32 val2) = game1.getNextRandom(0);
        assertTrue(ready2, "Should be ready");

        assertNotEq(val0, 0, "val0 is 0");
        assertNotEq(val1, 0, "val1 is 0");
        assertNotEq(val2, 0, "val2 is 0");
        assertNotEq(val0, val1, "val0, val1: Random Values equal");
        assertNotEq(val0, val2, "val0, val2: Random Values equal");
        assertNotEq(val1, val2, "val1, val2: Random Values equal");
    }

    function testGetRandomMultipleSequences() public {
        bool ready;
        bytes32 val0; bytes32 val1; bytes32 val2; bytes32 val3;
        bytes32 val4; bytes32 val5; bytes32 val6; bytes32 val7;

        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (ready, val0) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        (ready,) = game1.getNextRandom(1);
        assertFalse(ready, "Should not be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (ready, val1) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        (ready, val2) = game1.getNextRandom(1);
        assertTrue(ready, "Should be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (ready, val3) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        (ready, val4) = game1.getNextRandom(1);
        assertTrue(ready, "Should be ready");
        (ready,) = game1.getNextRandom(5);
        assertFalse(ready, "Should not be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (ready, val5) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        (ready, val6) = game1.getNextRandom(1);
        assertTrue(ready, "Should be ready");
        (ready, val7) = game1.getNextRandom(5);
        assertTrue(ready, "Should be ready");

        assertNotEq(val0, 0, "val0 is 0");
        assertNotEq(val1, 0, "val1 is 0");
        assertNotEq(val2, 0, "val2 is 0");
        assertNotEq(val3, 0, "val3 is 0");
        assertNotEq(val4, 0, "val4 is 0");
        assertNotEq(val5, 0, "val5 is 0");
        assertNotEq(val6, 0, "val6 is 0");
        assertNotEq(val7, 0, "val7 is 0");
        assertNotEq(val0, val1, "val0, val1: Random Values equal");
        assertNotEq(val0, val2, "val0, val2: Random Values equal");
        assertNotEq(val0, val3, "val0, val2: Random Values equal");
        assertNotEq(val0, val4, "val0, val2: Random Values equal");
        assertNotEq(val0, val5, "val0, val2: Random Values equal");
        assertNotEq(val0, val6, "val0, val2: Random Values equal");
        assertNotEq(val0, val7, "val0, val2: Random Values equal");
    }

    function testGetRandomMultiplePlayers() public {
        address player1 = makeAddr("player1");
        address player2 = makeAddr("player2");
        address player3 = makeAddr("player3");

        bool ready;
        bytes32 val0; bytes32 val1; bytes32 val2; bytes32 val3; bytes32 val4;

        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player1);
        (ready,) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player2);
        (ready,) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        // Happy case.
        vm.prank(player1);
        (ready, val0) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        // Player 1's second request is now in-progress.
        vm.prank(player1);
        (ready,) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");
        // Happy case.
        vm.prank(player2);
        (ready, val1) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player3);
        (ready,) = game1.getNextRandom(0);
        assertFalse(ready, "Should not be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        // Happy case.
        vm.prank(player1);
        (ready, val2) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        // Happy case.
        vm.prank(player2);
        (ready, val3) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");
        // Happy case.
        vm.prank(player3);
        (ready, val4) = game1.getNextRandom(0);
        assertTrue(ready, "Should be ready");

        assertNotEq(val0, 0, "val0 is 0");
        assertNotEq(val1, 0, "val1 is 0");
        assertNotEq(val2, 0, "val2 is 0");
        assertNotEq(val3, 0, "val3 is 0");
        assertNotEq(val4, 0, "val4 is 0");
        assertNotEq(val0, val1, "val0, val1: Random Values equal");
        assertNotEq(val0, val2, "val0, val2: Random Values equal");
        assertNotEq(val0, val3, "val0, val2: Random Values equal");
        assertNotEq(val0, val4, "val0, val2: Random Values equal");
    }

    function testMissedFulfillment() public {
        // First call will see that there is no initial request, and will request a random value.
        game1.getNextRandom(0);

        // Wait too long, and assume other seed fulfillment fails.
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 256);
        // The request will determine that the seed was not generated and a re-request is required.
        (bool ready0, ) = game1.getNextRandom(0);
        assertFalse(ready0, "Should not be ready");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        (bool ready1, bytes32 val1) = game1.getNextRandom(0);
        assertTrue(ready1, "Should be ready");

        assertNotEq(val1, 0, "val1 is 0");
    }
}


contract RandomSequencesStatusTest is BaseRandomSequencesTest {
    address public player1 = makeAddr("player1");

    function testStatusInvalidSequenceTypeId() public {
        RandomSequences.Status status = game1.randomStatus(player1, 100000);
        assertEq(uint256(status), uint256(RandomSequences.Status.SEQUENCE_ID_INVALID));
    }

    function testStatusNoExistingRequest() public {
        RandomSequences.Status status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.NO_INITIAL_REQUEST));
    }

    function testStatusInProgress() public {
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player1);
        game1.getNextRandom(0);
        // Second call in the same block will return that the random value is not ready yet.
        RandomSequences.Status status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.IN_PROGRESS));

    }

    function testStatusAlreadyFetched() public {
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player1);
        game1.getNextRandom(0);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        vm.prank(player1);
        game1.hackConsumeRandomValue(0);

        RandomSequences.Status status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.PREVIOUSLY_FETCHED));
    }

    function testStatusReady() public {
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player1);
        game1.getNextRandom(0);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        RandomSequences.Status status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.READY));
    }

    function testStatusRetyy() public {
        // First call will see that there is no initial request, and will request a random value.
        vm.prank(player1);
        game1.getNextRandom(0);
        // Wait too long, and assume other seed fulfillment fails.
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 256);
        RandomSequences.Status status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.RETRY));

        game1.getNextRandom(0);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        status = game1.randomStatus(player1, 0);
        assertEq(uint256(status), uint256(RandomSequences.Status.READY));
    }

}

