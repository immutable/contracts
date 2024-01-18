// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockCoordinator} from "./MockCoordinator.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import {ChainlinkSourceAdaptor} from "contracts/random/offchainsources/chainlink/ChainlinkSourceAdaptor.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ChainlinkSourceTest is Test {
    bytes32 public constant KEY_HASH = bytes32(uint256(1));
    uint64 public constant SUB_ID = uint64(4);
    uint32 public constant CALLBACK_GAS_LIMIT = uint32(200000);

    TransparentUpgradeableProxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;

    MockCoordinator public mockChainlinkCoordinator;
    ChainlinkSourceAdaptor public chainlinkSourceAdaptor;

    address public proxyAdmin;
    address public roleAdmin;
    address public randomAdmin;
    address public configAdmin;

    function setUp() public virtual {
        proxyAdmin = makeAddr("proxyAdmin");
        roleAdmin = makeAddr("roleAdmin");
        randomAdmin = makeAddr("randomAdmin");
        configAdmin = makeAddr("configAdmin");
        impl = new RandomSeedProvider();
        proxy = new TransparentUpgradeableProxy(address(impl), proxyAdmin, 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, false));
        randomSeedProvider = RandomSeedProvider(address(proxy));

        mockChainlinkCoordinator = new MockCoordinator();
        chainlinkSourceAdaptor = new ChainlinkSourceAdaptor(
            roleAdmin, configAdmin, address(mockChainlinkCoordinator), KEY_HASH, SUB_ID, CALLBACK_GAS_LIMIT);

        // Ensure we are on a new block number when we start the tests. In particular, don't 
        // be on the same block number as when the contracts were deployed.
        vm.roll(block.number + 1);
    }

    function testInit() public {
        mockChainlinkCoordinator = new MockCoordinator();
        chainlinkSourceAdaptor = new ChainlinkSourceAdaptor(
            roleAdmin, configAdmin, address(mockChainlinkCoordinator), KEY_HASH, SUB_ID, CALLBACK_GAS_LIMIT);

        assertEq(address(chainlinkSourceAdaptor.vrfCoordinator()), address(mockChainlinkCoordinator), "vrfCoord not set correctly");
        assertEq(chainlinkSourceAdaptor.keyHash(), KEY_HASH, "keyHash not set correctly");
        assertEq(chainlinkSourceAdaptor.subId(), SUB_ID, "subId not set correctly");
        assertEq(chainlinkSourceAdaptor.callbackGasLimit(), CALLBACK_GAS_LIMIT, "callbackGasLimit not set correctly");
    }
}


