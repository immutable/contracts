// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockGame} from "./MockGame.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/erc1967/ERC1967Proxy.sol";




contract UninitializedRandomValuesTest is Test {
    error WaitForRandom();

    address public constant ONCHAIN = address(0);

    ERC1967Proxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;

    MockGame public game1;

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
    uint256 public constant NUM_VALUES = 3;

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

    function testMultiFetch() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation();
        vm.roll(block.number + 1);
        bytes32 rand1a = game1.fetchRandom(randomRequestId1);
        vm.roll(block.number + 1);
        bytes32 rand1b = game1.fetchRandom(randomRequestId1);
        vm.roll(block.number + 1);
        bytes32 rand1c = game1.fetchRandom(randomRequestId1);

        assertEq(rand1a, rand1b, "rand1a, rand1b: Random Values not equal");
        assertEq(rand1a, rand1c, "rand1a, rand1c: Random Values not equal");
    }

    function testMultiInterleaved() public {
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


    function testFirstValues() public {
        uint256 randomRequestId = game1.requestRandomValueCreation();
        assertFalse(game1.isRandomValueReady(randomRequestId), "Ready in same block!");
        vm.roll(block.number + 1);
        assertTrue(game1.isRandomValueReady(randomRequestId), "Should be ready by next block!");

        bytes32 randomValue = game1.fetchRandom(randomRequestId);
        bytes32[] memory randomValues = game1.fetchRandomValues(randomRequestId, NUM_VALUES);
        assertEq(randomValues.length, NUM_VALUES, "wrong length");
        assertNotEq(randomValue, randomValues[0], "randomValue, values[0]: Random Values equal");
        assertNotEq(randomValue, randomValues[1], "randomValue, values[0]: Random Values equal");
        assertNotEq(randomValue, randomValues[2], "randomValue, values[0]: Random Values equal");
    }

    function testSecondValues() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation();
        uint256 randomRequestId2 = game1.requestRandomValueCreation();
        vm.roll(block.number + 1);

        bytes32[] memory randomValues1 = game1.fetchRandomValues(randomRequestId1, NUM_VALUES);
        bytes32[] memory randomValues2 = game1.fetchRandomValues(randomRequestId2, NUM_VALUES);

        assertNotEq(randomValues1[0], randomValues2[0], "values1[0], values2[0]: Random Values equal");
        assertNotEq(randomValues1[1], randomValues2[1], "values1[1], values2[1]: Random Values equal");
        assertNotEq(randomValues1[2], randomValues2[2], "values1[2], values2[2]: Random Values equal");
    }

    function testMultiFetchValues() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation();
        vm.roll(block.number + 1);
        bytes32[] memory randomValues1 = game1.fetchRandomValues(randomRequestId1, NUM_VALUES);
        vm.roll(block.number + 1);
        bytes32[] memory randomValues2 = game1.fetchRandomValues(randomRequestId1, NUM_VALUES);
        vm.roll(block.number + 1);
        bytes32[] memory randomValues3 = game1.fetchRandomValues(randomRequestId1, NUM_VALUES);

        assertEq(randomValues1[0], randomValues2[0], "values1[0], values2[0]: Random Values not equal");
        assertEq(randomValues1[1], randomValues2[1], "values1[1], values2[1]: Random Values not equal");
        assertEq(randomValues1[2], randomValues2[2], "values1[2], values2[2]: Random Values not equal");
        assertEq(randomValues1[0], randomValues3[0], "values1[0], values3[0]: Random Values not equal");
        assertEq(randomValues1[1], randomValues3[1], "values1[1], values3[1]: Random Values not equal");
        assertEq(randomValues1[2], randomValues3[2], "values1[2], values3[2]: Random Values not equal");
    }

    function testMultipleGames() public {
        MockGame game2 = new MockGame(address(randomSeedProvider));

        uint256 randomRequestId1 = game1.requestRandomValueCreation();
        uint256 randomRequestId2 = game2.requestRandomValueCreation();
        assertFalse(game1.isRandomValueReady(randomRequestId1), "Ready in same block!");
        assertFalse(game2.isRandomValueReady(randomRequestId2), "Ready in same block!");

        vm.roll(block.number + 1);
        assertTrue(game1.isRandomValueReady(randomRequestId1), "Should be ready by next block!");
        assertTrue(game2.isRandomValueReady(randomRequestId2), "Should be ready by next block!");

        bytes32 randomValue1 = game1.fetchRandom(randomRequestId1);
        bytes32 randomValue2 = game2.fetchRandom(randomRequestId2);
        assertNotEq(randomValue1, randomValue2, "Random Values equal");
    }

}
