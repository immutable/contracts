// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockGame} from "./MockGame.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";




contract UninitializedRandomValuesTest is Test {
    error WaitForRandom();

    address public constant ONCHAIN = address(0);

    TransparentUpgradeableProxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;
    TransparentUpgradeableProxy public proxyRanDao;
    RandomSeedProvider public randomSeedProviderRanDao;

    MockGame public game1;

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

        game1 = new MockGame(address(randomSeedProvider));

        // Ensure we are on a new block number when we start the tests. In particular, don't 
        // be on the same block number as when the contracts were deployed.
        vm.roll(block.number + 1);
    }

    function testInit() public {
        assertEq(address(game1.randomSeedProvider()), address(randomSeedProvider), "randomSeedProvider");
    }
}

contract SingleGameRandomValuesTest is UninitializedRandomValuesTest {
    function testFirstValue() public returns (bytes32) {
        uint256 randomRequestId = game1.requestRandomValueCreation();
        assertFalse(game1.isRandomValueReady(randomRequestId), "Ready in same block!");

        vm.roll(block.number + 1);
        assertTrue(game1.isRandomValueReady(randomRequestId), "Should be ready by next block!");

        bytes32 randomValue = game1.fetchRandom(randomRequestId);
        assertNotEq(randomValue, bytes32(0), "Random Value zero");
        return randomValue;
    }

    function testSecondValue() public {
        bytes32 rand1 = testFirstValue();
        bytes32 rand2 = testFirstValue();
        assertNotEq(rand1, rand2, "Random Values equal");
    }

    function testMultiRequestScenario() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation();
        uint256 randomRequestId2 = game1.requestRandomValueCreation();
        uint256 randomRequestId3 = game1.requestRandomValueCreation();
        vm.roll(block.number + 1);
        uint256 randomRequestId4 = game1.requestRandomValueCreation();
        bytes32 rand1a = game1.fetchRandom(randomRequestId1);
        assertFalse(game1.isRandomValueReady(randomRequestId4), "Ready in same block!");
        vm.roll(block.number + 1);
        bytes32 rand1b = game1.fetchRandom(randomRequestId1);
        bytes32 rand2 = game1.fetchRandom(randomRequestId2);
        bytes32 rand3 = game1.fetchRandom(randomRequestId3);
        bytes32 rand4 = game1.fetchRandom(randomRequestId4);
        game1.requestRandomValueCreation();
        vm.roll(block.number + 1);
        bytes32 rand1c = game1.fetchRandom(randomRequestId1);

        assertNotEq(rand1a, rand2, "rand1a, rand2: Random Values equal");
        assertNotEq(rand1a, rand3, "rand1a, rand3: Random Values equal");
        assertNotEq(rand1a, rand4, "rand1a, rand4: Random Values equal");
        assertEq(rand1a, rand1b, "rand1a, rand1b: Random Values not equal");
        assertEq(rand1a, rand1c, "rand1a, rand1c: Random Values not equal");
    }
}
