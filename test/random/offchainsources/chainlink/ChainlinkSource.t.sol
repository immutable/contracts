// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockCoordinator} from "./MockCoordinator.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import {ChainlinkSourceAdaptor} from "contracts/random/offchainsources/chainlink/ChainlinkSourceAdaptor.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ChainlinkInitTest is Test {
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


contract ChainlinkControlTests is ChainlinkInitTest {
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


contract ChainlinkOperationalTests is ChainlinkInitTest {
    event RequestId(uint256 _requestId);

    bytes32 public constant RAND = bytes32(uint256(0x1a));

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

        mockChainlinkCoordinator.sendFulfill(fulfilmentIndex, uint256(RAND));

        ready = chainlinkSourceAdaptor.isOffchainRandomReady(fulfilmentIndex);
        assertTrue(ready, "Should be ready");

        bytes32 rand = chainlinkSourceAdaptor.getOffchainRandom(fulfilmentIndex);
        assertEq(rand, RAND, "Wrong value returned");
    }
}

