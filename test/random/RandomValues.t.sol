// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockGame,RandomValues} from "./MockGame.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";




contract UninitializedRandomValuesTest is Test {
    error RequestForNoRandomBytes();
    error RandomValuesPreviouslyFetched();
    error WaitForRandom();

    address public constant ONCHAIN = address(0);
    uint256 public constant STANDARD_ONCHAIN_DELAY = 2;

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
        assertEq(uint256(game1.isRandomValueReady(0)), uint256(RandomValues.RequestStatus.ALREADY_FETCHED), "Should not be ready");
    }
}

contract SingleGameRandomValuesTest is UninitializedRandomValuesTest {
    uint16 public constant NUM_VALUES = 3;

    function testNoValues() public {
        vm.expectRevert(abi.encodeWithSelector(RequestForNoRandomBytes.selector));
        game1.requestRandomValueCreation(0);
    }

    function testFirstValue() public returns (bytes32) {
        uint256 randomRequestId = game1.requestRandomValueCreation(1);
        assertEq(uint256(game1.isRandomValueReady(randomRequestId)), uint256(RandomValues.RequestStatus.IN_PROGRESS), "Ready in same block!");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        assertEq(uint256(game1.isRandomValueReady(randomRequestId)), uint256(RandomValues.RequestStatus.READY), "Should be ready by next block!");

        bytes32[] memory randomValue = game1.fetchRandomValues(randomRequestId);
        assertEq(randomValue.length, 1, "Random Values length");
        assertNotEq(randomValue[0], bytes32(0), "Random Value zero");

        assertEq(uint256(game1.isRandomValueReady(randomRequestId)), uint256(RandomValues.RequestStatus.ALREADY_FETCHED), "Should not be ready");
        return randomValue[0];
    }

    function testSecondValue() public {
        bytes32 rand1 = testFirstValue();
        bytes32 rand2 = testFirstValue();
        assertNotEq(rand1, rand2, "Random Values equal");
    }

    function testMultiFetch() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation(1);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        game1.fetchRandomValues(randomRequestId1);
        vm.roll(block.number + 1);
        vm.expectRevert(abi.encodeWithSelector(RandomValuesPreviouslyFetched.selector));
        game1.fetchRandomValues(randomRequestId1);
    }

    function testFirstValues() public {
        uint256 randomRequestId = game1.requestRandomValueCreation(NUM_VALUES);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        bytes32[] memory randomValues = game1.fetchRandomValues(randomRequestId);
        assertEq(randomValues.length, NUM_VALUES, "wrong length");
    }

    function testSecondValues() public {
        uint256 randomRequestId1 = game1.requestRandomValueCreation(NUM_VALUES);
        uint256 randomRequestId2 = game1.requestRandomValueCreation(NUM_VALUES);
        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);

        bytes32[] memory randomValues1 = game1.fetchRandomValues(randomRequestId1);
        bytes32[] memory randomValues2 = game1.fetchRandomValues(randomRequestId2);

        assertNotEq(randomValues1[0], randomValues2[0], "values1[0], values2[0]: Random Values equal");
        assertNotEq(randomValues1[1], randomValues2[1], "values1[1], values2[1]: Random Values equal");
        assertNotEq(randomValues1[2], randomValues2[2], "values1[2], values2[2]: Random Values equal");
    }

    function testMultipleGames() public {
        MockGame game2 = new MockGame(address(randomSeedProvider));

        uint256 randomRequestId1 = game1.requestRandomValueCreation(2);
        uint256 randomRequestId2 = game2.requestRandomValueCreation(4);
        assertEq(uint256(game1.isRandomValueReady(randomRequestId1)), uint256(RandomValues.RequestStatus.IN_PROGRESS), "Ready in same block!");
        assertEq(uint256(game2.isRandomValueReady(randomRequestId2)), uint256(RandomValues.RequestStatus.IN_PROGRESS), "Ready in same block!");

        vm.roll(block.number + STANDARD_ONCHAIN_DELAY + 1);
        assertEq(uint256(game1.isRandomValueReady(randomRequestId1)), uint256(RandomValues.RequestStatus.READY), "Ready!");
        assertEq(uint256(game2.isRandomValueReady(randomRequestId2)), uint256(RandomValues.RequestStatus.READY), "Ready!");

        bytes32[] memory randomValue1 = game1.fetchRandomValues(randomRequestId1);
        bytes32[] memory randomValue2 = game2.fetchRandomValues(randomRequestId2);
        assertEq(randomValue1.length, 2, "randomValue1 size");
        assertEq(randomValue2.length, 4, "randomValue2 size");
    }
}
