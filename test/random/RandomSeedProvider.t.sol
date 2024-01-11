// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";



contract MockOffchainSource is IOffchainRandomSource {
    uint256 public nextIndex = 1000;
    bool public isReady;

    function setIsReady(bool _ready) external {
        isReady = _ready;
    }

    function requestOffchainRandom() external override(IOffchainRandomSource) returns(uint256 _fulfillmentIndex) {
        return nextIndex++;
    }

    function getOffchainRandom(uint256 _fulfillmentIndex) external view override(IOffchainRandomSource) returns(bytes32 _randomValue) {
        if (!isReady) {
            revert WaitForRandom();
        }
        return keccak256(abi.encodePacked(_fulfillmentIndex));
    }

    function isOffchainRandomReady(uint256 /* _fulfillmentIndex */) external view returns(bool) {
        return isReady;
    }


}

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
    }

    function testInit() public {
        assertEq(randomSeedProvider.nextRandomIndex(), 1, "nextRandomIndex");
        assertEq(randomSeedProvider.lastBlockRandomGenerated(), block.number, "lastBlockRandomGenerated");
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
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number));
        assertEq(seed, expectedInitialSeed, "initial seed");
    }

    function testGetRandomSeedInitRandao() public {
        bytes32 seed = randomSeedProviderRanDao.getRandomSeed(0, ONCHAIN);
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number));
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

}
