// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/IOffchainRandomSource.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";



contract MockOffchainSource is IOffchainRandomSource {
    uint256 public nextIndex;
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

    address public constant TRADITIONAL = address(0);
    address public constant RANDAO = address(1);

    TransparentUpgradeableProxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;

    address public proxyAdmin;
    address public roleAdmin;
    address public randomAdmin;

    function setUp() public virtual {
        proxyAdmin = makeAddr("proxyAdmin");
        roleAdmin = makeAddr("roleAdmin");
        randomAdmin = makeAddr("randomAdmin");
        impl = new RandomSeedProvider();
        proxy = new TransparentUpgradeableProxy(address(impl), proxyAdmin, 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin));
        randomSeedProvider = RandomSeedProvider(address(proxy));
    }

    function testInit() public {
        assertEq(randomSeedProvider.nextRandomIndex(), 1, "nextRandomIndex");
        assertEq(randomSeedProvider.lastBlockRandomGenerated(), block.number, "lastBlockRandomGenerated");
        assertEq(randomSeedProvider.offchainRequestRateLimit(), 0, "offchainRequestRateLimit");
        assertEq(randomSeedProvider.prevOffchainRandomRequest(), 0, "prevOffchainRandomRequest");
        assertEq(randomSeedProvider.lastBlockOffchainRequest(), 0, "lastBlockOffchainRequest");
        assertEq(randomSeedProvider.randomSource(), TRADITIONAL, "lastBlockOffchainRequest");
    }

    function testReinit() public {
        vm.expectRevert();
        randomSeedProvider.initialize(roleAdmin, randomAdmin);
    }


    function testGetRandomSeedInitTraditional() public {
        bytes32 seed = randomSeedProvider.getRandomSeed(0, TRADITIONAL);
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number));
        assertEq(seed, expectedInitialSeed, "initial seed");
    }

    function testGetRandomSeedInitRandao() public {
        bytes32 seed = randomSeedProvider.getRandomSeed(0, RANDAO);
        bytes32 expectedInitialSeed = keccak256(abi.encodePacked(block.chainid, block.number));
        assertEq(seed, expectedInitialSeed, "initial seed");
    }

    function testGetRandomSeedNotGenTraditional() public {
        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector));
        randomSeedProvider.getRandomSeed(2, TRADITIONAL);
    }

    function testGetRandomSeedNotGenRandao() public {
        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector));
        randomSeedProvider.getRandomSeed(2, RANDAO);
    }

    function testGetRandomSeedNoOffchainSource() public {
        vm.expectRevert();
        randomSeedProvider.getRandomSeed(0, address(1000));
    }

}
