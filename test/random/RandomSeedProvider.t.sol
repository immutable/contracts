// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockOffchainSource} from "./MockOffchainSource.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";




contract UninitializedRandomSeedProviderTest is Test {
    error WaitForRandom();

    address public constant ONCHAIN = address(0);

    TransparentUpgradeableProxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;
    TransparentUpgradeableProxy public proxyRanDao;
    RandomSeedProvider public randomSeedProviderRanDao;


    address public proxyAdmin;
    address public roleAdmin;
    address public randomAdmin;

    function setUp() public virtual {
        proxyAdmin = makeAddr("proxyAdmin");
        roleAdmin = makeAddr("roleAdmin");
        randomAdmin = makeAddr("randomAdmin");
        impl = new RandomSeedProvider();
        proxy = new TransparentUpgradeableProxy(address(impl), proxyAdmin, 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, false));
        randomSeedProvider = RandomSeedProvider(address(proxy));

        proxyRanDao = new TransparentUpgradeableProxy(address(impl), proxyAdmin, 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, true));
        randomSeedProviderRanDao = RandomSeedProvider(address(proxyRanDao));

        // Ensure we are on a new block number when we start the tests. In particular, don't 
        // be on the same block number as when the contracts were deployed.
        vm.roll(block.number + 1);
    }

    function testInit() public {
        assertEq(randomSeedProvider.nextRandomIndex(), 1, "nextRandomIndex");
        assertEq(randomSeedProvider.lastBlockRandomGenerated(), block.number - 1, "lastBlockRandomGenerated");
        assertEq(randomSeedProvider.prevOffchainRandomRequest(), 0, "prevOffchainRandomRequest");
        assertEq(randomSeedProvider.lastBlockOffchainRequest(), 0, "lastBlockOffchainRequest");
        assertEq(randomSeedProvider.randomSource(), ONCHAIN, "randomSource");
    }

    function testReinit() public {
        vm.expectRevert();
        randomSeedProvider.initialize(roleAdmin, randomAdmin, true);
    }


    function testGetRandomSeedInitTraditional() public {
        bytes32 seed = randomSeedProvider.getRandomSeed(0, ONCHAIN);
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number - 1));
        assertEq(seed, expectedInitialSeed, "initial seed");
    }

    function testGetRandomSeedInitRandao() public {
        bytes32 seed = randomSeedProviderRanDao.getRandomSeed(0, ONCHAIN);
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number - 1));
        assertEq(seed, expectedInitialSeed, "initial seed");
    }

    function testGetRandomSeedNotGenTraditional() public {
        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector));
        randomSeedProvider.getRandomSeed(2, ONCHAIN);
    }

    function testGetRandomSeedNotGenRandao() public {
        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector));
        randomSeedProviderRanDao.getRandomSeed(2, ONCHAIN);
    }

    function testGetRandomSeedNoOffchainSource() public {
        vm.expectRevert();
        randomSeedProvider.getRandomSeed(0, address(1000));
    }
}

contract OperationalRandomSeedProviderTest is UninitializedRandomSeedProviderTest {
    MockOffchainSource public offchainSource = new MockOffchainSource();


    function testTradNextBlock () public {
        (uint256 fulfillmentIndex, address source) = randomSeedProvider.requestRandomSeed();
        assertEq(source, ONCHAIN, "source");
        assertEq(fulfillmentIndex, 2, "index");

        bool available = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertFalse(available, "Should not be ready yet");

        vm.roll(block.number + 1);

        available = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertTrue(available, "Should be ready");

        randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
    }

    function testOffchainNextBlock () public {
        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex, address source) = randomSeedProvider.requestRandomSeed();
        assertEq(source, address(offchainSource), "source");
        assertEq(fulfillmentIndex, 1000, "index");

        bool available = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertFalse(available, "Should not be ready yet");

        offchainSource.setIsReady(true);

        available = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertTrue(available, "Should be ready");

        randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
    }

    function testMultiRequestSameBlock() public {
        (uint256 randomRequestId1, ) = randomSeedProvider.requestRandomSeed();
        (uint256 randomRequestId2, ) = randomSeedProvider.requestRandomSeed();
        (uint256 randomRequestId3, ) = randomSeedProvider.requestRandomSeed();
        assertEq(randomRequestId1, randomRequestId2, "Request id 1 and request id 2");
        assertEq(randomRequestId1, randomRequestId3, "Request id 1 and request id 3");
    }



    function testMultiRequestScenario() public {
        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        vm.roll(block.number + 1);

        (uint256 randomRequestId2, address source2) = randomSeedProvider.requestRandomSeed();
        bytes32 rand1a = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1a, bytes32(0), "rand1a: Random Values is zero");
        (uint256 randomRequestId3,) = randomSeedProvider.requestRandomSeed();
        assertNotEq(randomRequestId1, randomRequestId2, "Request id 1 and request id 2");
        assertEq(randomRequestId2, randomRequestId3, "Request id 2 and request id 3");

        vm.roll(block.number + 1);
        bytes32 rand1b = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1b, bytes32(0), "rand1b: Random Values is zero");
        {
            bytes32 rand2 = randomSeedProvider.getRandomSeed(randomRequestId2, source2);
            assertNotEq(rand2, bytes32(0), "rand2: Random Values is zero");
            assertNotEq(rand1a, rand2, "rand1a, rand2: Random Values equal");
        }
        vm.roll(block.number + 1);
        bytes32 rand1c = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1c, bytes32(0), "rand1c: Random Values is zero");

        assertEq(rand1a, rand1b, "rand1a, rand1b: Random Values not equal");
        assertEq(rand1a, rand1c, "rand1a, rand1c: Random Values not equal");
    }
}
