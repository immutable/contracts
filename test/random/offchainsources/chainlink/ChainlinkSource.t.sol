// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockCoordinator} from "./MockCoordinator.sol";
import {MockGame} from "../../MockGame.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import {ChainlinkSourceAdaptor} from "contracts/random/offchainsources/chainlink/ChainlinkSourceAdaptor.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ChainlinkInitTests is Test {
    event ConfigChanges( bytes32 _keyHash, uint64 _subId, uint32 _callbackGasLimit);

    bytes32 public constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

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
        mockChainlinkCoordinator.setAdaptor(address(chainlinkSourceAdaptor));

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(chainlinkSourceAdaptor));

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


contract ChainlinkControlTests is ChainlinkInitTests {
    function testRoleAdmin() public {
        bytes32 role = CONFIG_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");

        vm.prank(roleAdmin);
        chainlinkSourceAdaptor.grantRole(role, newAdmin);
        assertTrue(chainlinkSourceAdaptor.hasRole(role, newAdmin));
    }

    function testRoleAdminBadAuth() public {
        bytes32 role = CONFIG_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");
        vm.expectRevert();
        chainlinkSourceAdaptor.grantRole(role, newAdmin);
    }

    function testConfigureRequests() public {
        bytes32 keyHash = bytes32(uint256(2));
        uint64 subId = uint64(5);
        uint32 callbackGasLimit = uint32(200001);

        vm.prank(configAdmin);
        vm.expectEmit(true, true, true, true);
        emit ConfigChanges(keyHash, subId, callbackGasLimit);
        chainlinkSourceAdaptor.configureRequests(keyHash, subId, callbackGasLimit);
        assertEq(chainlinkSourceAdaptor.keyHash(), keyHash, "keyHash not set correctly");
        assertEq(chainlinkSourceAdaptor.subId(), subId, "subId not set correctly");
        assertEq(chainlinkSourceAdaptor.callbackGasLimit(), callbackGasLimit, "callbackGasLimit not set correctly");
    }

    function testConfigureRequestsBadAuth() public {
        bytes32 keyHash = bytes32(uint256(2));
        uint64 subId = uint64(5);
        uint32 callbackGasLimit = uint32(200001);

        vm.expectRevert(); 
        chainlinkSourceAdaptor.configureRequests(keyHash, subId, callbackGasLimit);
    }
}


contract ChainlinkOperationalTests is ChainlinkInitTests {
    error WaitForRandom();
    error UnexpectedRandomWordsLength(uint256 _length);
    event RequestId(uint256 _requestId);

    bytes32 public constant RAND1 = bytes32(uint256(0x1a));
    bytes32 public constant RAND2 = bytes32(uint256(0x1b));

    function testRequestRandom() public {
        vm.recordLogs();
        uint256 fulfilmentIndex = chainlinkSourceAdaptor.requestOffchainRandom();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics[0], keccak256("RequestId(uint256)"));
        uint256 requestId = abi.decode(entries[0].data, (uint256));
        assertEq(fulfilmentIndex, requestId, "Must be the same");


        bool ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex);
        assertFalse(ready, "Should not be ready yet");

        mockChainlinkCoordinator.sendFulfill(fulfilmentIndex, uint256(RAND1));

        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex);
        assertTrue(ready, "Should be ready");

        bytes32 rand = chainlinkSourceAdaptor.getOffchainRandom(fulfilmentIndex);
        assertEq(rand, RAND1, "Wrong value returned");
    }

    function testTwoRequests() public {
        uint256 fulfilmentIndex1 = chainlinkSourceAdaptor.requestOffchainRandom();
        uint256 fulfilmentIndex2 = chainlinkSourceAdaptor.requestOffchainRandom();
        assertNotEq(fulfilmentIndex1, fulfilmentIndex2, "Different requests receive different indices");

        bool ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertFalse(ready, "Should not be ready yet1");
        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertFalse(ready, "Should not be ready yet2");

        mockChainlinkCoordinator.sendFulfill(fulfilmentIndex2, uint256(RAND2));
        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertFalse(ready, "Should not be ready yet3");
        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertTrue(ready, "Should be ready1");

        bytes32 rand = chainlinkSourceAdaptor.getOffchainRandom(fulfilmentIndex2);
        assertEq(rand, RAND2, "Wrong value returned1");

        mockChainlinkCoordinator.sendFulfill(fulfilmentIndex1, uint256(RAND1));
        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertTrue(ready, "Should be ready2");
        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertTrue(ready, "Should be ready3");

        rand = chainlinkSourceAdaptor.getOffchainRandom(fulfilmentIndex1);
        assertEq(rand, RAND1, "Wrong value returned2");
    }

    function testBadFulfilment() public {
        uint256 fulfilmentIndex = chainlinkSourceAdaptor.requestOffchainRandom();

        uint256 length = 2;
        uint256[] memory randomWords = new uint256[](length);
        randomWords[0] = uint256(RAND1);

        vm.expectRevert(abi.encodeWithSelector(UnexpectedRandomWordsLength.selector, length));
        mockChainlinkCoordinator.sendFulfillRaw(fulfilmentIndex, randomWords);
    }

    function testRequestTooEarly() public {
        uint256 fulfilmentIndex = chainlinkSourceAdaptor.requestOffchainRandom();

        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector));
        chainlinkSourceAdaptor.getOffchainRandom(fulfilmentIndex);
    }
}



contract ChainlinkIntegrationTests is ChainlinkOperationalTests {
    function testEndToEnd() public {
        MockGame game = new MockGame(address(randomSeedProvider));

        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(address(game));

        vm.recordLogs();
        uint256 randomRequestId = game.requestRandomValueCreation();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Unexpected number of events emitted");
        assertEq(entries[0].topics[0], keccak256("RequestId(uint256)"));
        uint256 fulfilmentIndex = abi.decode(entries[0].data, (uint256));

        assertFalse(game.isRandomValueReady(randomRequestId), "Should not be ready yet");

        mockChainlinkCoordinator.sendFulfill(fulfilmentIndex, uint256(RAND1));

        assertTrue(game.isRandomValueReady(randomRequestId), "Should be ready");

        bytes32 randomValue = game.fetchRandom(randomRequestId);
        assertNotEq(randomValue, bytes32(0), "Random Value zero");
    }
}

contract ChainlinkCoverageFakeTests is ChainlinkInitTests {
        // Do calls to unused functions in MockCoordinator so that it doesn't impact the coverage results.
    function testFixMockCoordinatorCoverage() public {
        mockChainlinkCoordinator = new MockCoordinator();
        mockChainlinkCoordinator.setAdaptor(address(chainlinkSourceAdaptor));
        mockChainlinkCoordinator.getRequestConfig();
        uint64 subId = mockChainlinkCoordinator.createSubscription();
        mockChainlinkCoordinator.getSubscription(subId);
        mockChainlinkCoordinator.requestSubscriptionOwnerTransfer(subId, address(0));
        mockChainlinkCoordinator.acceptSubscriptionOwnerTransfer(subId);
        mockChainlinkCoordinator.addConsumer(subId, address(0));
        mockChainlinkCoordinator.removeConsumer(subId, address(0));
        mockChainlinkCoordinator.cancelSubscription(subId, address(0));
        mockChainlinkCoordinator.pendingRequestExists(subId);
    }
}

