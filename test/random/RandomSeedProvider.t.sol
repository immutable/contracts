// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockOffchainSource} from "./MockOffchainSource.sol";
import {MockRandomSeedProviderV2} from "./MockRandomSeedProviderV2.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract RandomSeedProviderBase is Test {
    error OffchainWaitForRandom();
    error WaitForRandom(uint256 _fulfillmentId);
    error GenerationFailedTryAgain(uint256 _fulfillmentId);
    event OffchainRandomSourceSet(address _offchainRandomSource);
    event OffchainRandomConsumerAdded(address _consumer);
    event OffchainRandomConsumerRemoved(address _consumer);

    bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");
    bytes32 public constant UPGRADE_ADMIN_ROLE = bytes32("UPGRADE_ROLE");

    address public constant ONCHAIN = address(1);

    uint256 public constant STANDARD_ONCHAIN_DELAY = 2;

    ERC1967Proxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;
    ERC1967Proxy public proxyRanDao;
    RandomSeedProvider public randomSeedProviderRanDao;


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

        // Don't be on the same block number as when the contracts were deployed.
        vm.roll(block.number + 1);
    }
}

contract UninitializedRandomSeedProviderTest is RandomSeedProviderBase {
    function testInit() public {
        // This set-up mirrors what is in the setUp function. Have this code here
        // so that the coverage tool picks up the use of the initialize function.
        RandomSeedProvider impl1 = new RandomSeedProvider();
        ERC1967Proxy proxy1 = new ERC1967Proxy(address(impl1), 
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, upgradeAdmin, false));
        RandomSeedProvider randomSeedProvider1 = RandomSeedProvider(address(proxy1));
        vm.roll(block.number + 1);

        // Check  that the initialize funciton has worked correctly.
        (uint256 lastBlock, uint256 queueLen) = randomSeedProvider1.onchainGenerationStatus();
        assertEq(lastBlock, 0, "last block");
        assertEq(queueLen, 0, "queue len");
        assertEq(randomSeedProvider1.randomSource(), ONCHAIN, "randomSource");
        assertEq(randomSeedProvider1.onChainDelay(), 2, "on chain delay");

        assertTrue(randomSeedProvider1.hasRole(DEFAULT_ADMIN_ROLE, roleAdmin));
        assertTrue(randomSeedProvider1.hasRole(RANDOM_ADMIN_ROLE, randomAdmin));
        assertTrue(randomSeedProvider1.hasRole(UPGRADE_ADMIN_ROLE, upgradeAdmin));
    }

    function testReinit() public {
        vm.expectRevert();
        randomSeedProvider.initialize(roleAdmin, randomAdmin, upgradeAdmin);
    }

    function testGetRandomSeedOld() public {
        vm.roll(block.number + 1000);
        vm.expectRevert(abi.encodeWithSelector(GenerationFailedTryAgain.selector, block.number - 1000));
        randomSeedProvider.getRandomSeed(block.number - 1000, ONCHAIN);
    }

    function testGetRandomSeedNotGen() public {
        // 2 is the default onchain delay
        vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector, block.number));
        randomSeedProvider.getRandomSeed(block.number, ONCHAIN);
    }

    function testGetRandomSeedNoOffchainSource() public {
        vm.expectRevert();
        randomSeedProvider.getRandomSeed(0, address(1000));
    }
}


contract ControlRandomSeedProviderTest is RandomSeedProviderBase {
    error CanNotUpgradeFrom(uint256 _storageVersion, uint256 _codeVersion);
    event Upgraded(address indexed implementation);

    address public constant NEW_SOURCE = address(10001);
    address public constant CONSUMER = address(10001);

    function testRoleAdmin() public {
        bytes32 role = RANDOM_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");

        vm.prank(roleAdmin);
        randomSeedProvider.grantRole(role, newAdmin);
        assertTrue(randomSeedProvider.hasRole(role, newAdmin));
    }

    function testRoleAdminBadAuth() public {
        bytes32 role = RANDOM_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");
        vm.expectRevert();
        randomSeedProvider.grantRole(role, newAdmin);
    }

    function testSetOffchainRandomSource() public {
        vm.prank(randomAdmin);
        vm.expectEmit(true, true, true, true);
        emit OffchainRandomSourceSet(NEW_SOURCE);
        randomSeedProvider.setOffchainRandomSource(NEW_SOURCE);
        assertEq(randomSeedProvider.randomSource(), NEW_SOURCE);
    }

    function testSetOffchainRandomSourceBadAuth() public {
        vm.expectRevert();
        randomSeedProvider.setOffchainRandomSource(NEW_SOURCE);
    }

    function testAddOffchainRandomConsumer() public {
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), false);
        vm.prank(randomAdmin);
        vm.expectEmit(true, true, true, true);
        emit OffchainRandomConsumerAdded(CONSUMER);
        randomSeedProvider.addOffchainRandomConsumer(CONSUMER);
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), true);
    }

    function testAddOffchainRandomConsumerBadAuth() public {
        vm.expectRevert();
        randomSeedProvider.addOffchainRandomConsumer(CONSUMER);
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), false);
    }

    function testRemoveOffchainRandomConsumer() public {
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(CONSUMER);
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), true);
        vm.prank(randomAdmin);
        vm.expectEmit(true, true, true, true);
        emit OffchainRandomConsumerRemoved(CONSUMER);
        randomSeedProvider.removeOffchainRandomConsumer(CONSUMER);
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), false);
    }

    function testRemoveOffchainRandomConsumerBadAuth() public {
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(CONSUMER);
        vm.expectRevert();
        randomSeedProvider.removeOffchainRandomConsumer(CONSUMER);
        assertEq(randomSeedProvider.approvedForOffchainRandom(CONSUMER), true);
    }

    function testUpgrade() public {
        assertEq(randomSeedProvider.version(), 0);

        MockRandomSeedProviderV2 randomSeedProviderV2 = new MockRandomSeedProviderV2();

        vm.prank(upgradeAdmin);
        vm.expectEmit(true, true, true, true);
        emit Upgraded(address(randomSeedProviderV2));
        randomSeedProvider.upgradeToAndCall(address(randomSeedProviderV2), 
            abi.encodeWithSelector(randomSeedProviderV2.upgrade.selector, bytes("")));
        assertEq(randomSeedProvider.version(), 2);
    }

    function testUpgradeBadAuth() public {
        MockRandomSeedProviderV2 randomSeedProviderV2 = new MockRandomSeedProviderV2();

        vm.expectRevert();
        randomSeedProvider.upgradeToAndCall(address(randomSeedProviderV2), 
            abi.encodeWithSelector(randomSeedProviderV2.upgrade.selector, bytes("")));
    }

    function testNoUpgrade() public {
        bytes memory data = "";
        vm.prank(upgradeAdmin);
        vm.expectRevert(abi.encodeWithSelector(CanNotUpgradeFrom.selector, 0, 0));
        randomSeedProvider.upgrade(data);
    }

    function testNoDowngrade() public {
        MockRandomSeedProviderV2 randomSeedProviderV2 = new MockRandomSeedProviderV2();
        RandomSeedProvider randomSeedProviderV0 = new RandomSeedProvider();

        vm.prank(upgradeAdmin);
        randomSeedProvider.upgradeToAndCall(address(randomSeedProviderV2), 
            abi.encodeWithSelector(randomSeedProviderV2.upgrade.selector, bytes("")));

        vm.prank(upgradeAdmin);
        vm.expectRevert(abi.encodeWithSelector(CanNotUpgradeFrom.selector, 2, 0));
        randomSeedProvider.upgradeToAndCall(address(randomSeedProviderV0), 
            abi.encodeWithSelector(randomSeedProviderV0.upgrade.selector, bytes("")));
    }

    // Check that the downgrade code in MockRandomSeedProviderV2 works too.
    function testV2NoDowngrade() public {
        // Note that this test relies on the storage layout of RandomSeedProvider.
        // To get the storage layout: forge inspect RandomSeedProvider storageLayout
        uint256 badVersion = 13;
        uint256 versionStorageSlot = 404;
        vm.store(address(randomSeedProvider), bytes32(versionStorageSlot), bytes32(badVersion));
        // Check that the fake version has been set-up correctly. This will fail if the storage
        // slot for version changes.
        assertEq(randomSeedProvider.version(), badVersion);

        MockRandomSeedProviderV2 randomSeedProviderV2 = new MockRandomSeedProviderV2();

        vm.prank(upgradeAdmin);
        vm.expectRevert(abi.encodeWithSelector(CanNotUpgradeFrom.selector, badVersion, 2));
        randomSeedProvider.upgradeToAndCall(address(randomSeedProviderV2), 
            abi.encodeWithSelector(randomSeedProviderV2.upgrade.selector, bytes("")));
    }

    function testSetOnchainDelay() public {
        vm.prank(randomAdmin);
        randomSeedProvider.setOnChainDelay(3);
        assertEq(randomSeedProvider.onChainDelay(), 3);
    }

    function testSetOnchainDelayBadAuth() public {
        vm.expectRevert();
        randomSeedProvider.setOnChainDelay(3);
        assertEq(randomSeedProvider.onChainDelay(), 2);
    }

    function testSetOnchainDelayInvalid() public {
        vm.prank(randomAdmin);
        vm.expectRevert(abi.encodeWithSelector(RandomSeedProvider.InvalidOnchainDelay.selector, 0));
        randomSeedProvider.setOnChainDelay(0);

        vm.prank(randomAdmin);
        vm.expectRevert(abi.encodeWithSelector(RandomSeedProvider.InvalidOnchainDelay.selector, 70));
        randomSeedProvider.setOnChainDelay(70);
    }
}


contract OperationalRandomSeedProviderTest is RandomSeedProviderBase {
    event TooLateToGenerateRandom(uint256 _blockNumber);
    MockOffchainSource public offchainSource = new MockOffchainSource();

    function testOnchainNextBlock() public {
        (uint256 fulfillmentIndex, address source) = randomSeedProvider.requestRandomSeed();
        assertEq(source, ONCHAIN, "source");
        assertEq(fulfillmentIndex, block.number + STANDARD_ONCHAIN_DELAY, "index");

        RandomSeedProvider.SeedRequestStatus status;
        for (uint256 i = block.number; i <= fulfillmentIndex; i++) {
            status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
            assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.IN_PROGRESS), "Should not be ready yet");
            vm.expectRevert(abi.encodeWithSelector(WaitForRandom.selector, fulfillmentIndex));
            randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
            vm.roll(block.number + 1);
        }

        status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.READY), "Should be ready");

        bytes32 seed = randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
        assertNotEq(seed, bytes32(0), "Should not be zero");
    }

    function testOffchainNextBlock() public {
        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex, address source) = randomSeedProvider.requestRandomSeed();
        assertEq(source, address(offchainSource), "source");
        assertEq(fulfillmentIndex, 1000, "index");

        RandomSeedProvider.SeedRequestStatus status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.IN_PROGRESS), "Should not be ready yet");

        offchainSource.setIsReady(true);

        status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex, source);
        assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.READY), "Should be ready");

        bytes32 seed = randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
        assertNotEq(seed, bytes32(0), "Should not be zero");
    }

    function testOffchainNotReady() public {
        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex, address source) = randomSeedProvider.requestRandomSeed();

        vm.expectRevert(abi.encodeWithSelector(OffchainWaitForRandom.selector));
        randomSeedProvider.getRandomSeed(fulfillmentIndex, source);
    }

    function testOnchainTwoInOneBlock() public {
        (uint256 randomRequestId1, ) = randomSeedProvider.requestRandomSeed();
        (uint256 randomRequestId2, ) = randomSeedProvider.requestRandomSeed();
        (uint256 randomRequestId3, ) = randomSeedProvider.requestRandomSeed();
        assertEq(randomRequestId1, randomRequestId2, "Request id 1 and request id 2");
        assertEq(randomRequestId1, randomRequestId3, "Request id 1 and request id 3");
    }

    function testOffchainTwoInOneBlock() public {
        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex1, ) = randomSeedProvider.requestRandomSeed();
        vm.prank(aConsumer);
        (uint256 fulfillmentIndex2, ) = randomSeedProvider.requestRandomSeed();
        assertEq(fulfillmentIndex1, fulfillmentIndex2, "Request id 1 and request id 3");
    }

    function testOnchainDelayedFulfillment() public {
        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        vm.roll(randomRequestId1 + 1);

        (uint256 randomRequestId2, address source2) = randomSeedProvider.requestRandomSeed();
        bytes32 rand1a = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1a, bytes32(0), "rand1a: Random Values is zero");
        (uint256 randomRequestId3,) = randomSeedProvider.requestRandomSeed();
        assertNotEq(randomRequestId1, randomRequestId2, "Request id 1 and request id 2");
        assertEq(randomRequestId2, randomRequestId3, "Request id 2 and request id 3");

        vm.roll(randomRequestId2 + 1);
        bytes32 rand1b = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1b, bytes32(0), "rand1b: Random Values is zero");
        {
            bytes32 rand2 = randomSeedProvider.getRandomSeed(randomRequestId2, source2);
            assertNotEq(rand2, bytes32(0), "rand2: Random Values is zero");
            assertNotEq(rand1a, rand2, "rand1a, rand2: Random Values equal");
        }

        // Check that random request id 1 can be re-fetched at a later block.
        vm.roll(block.number + 1);
        bytes32 rand1c = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1c, bytes32(0), "rand1c: Random Values is zero");

        assertEq(rand1a, rand1b, "rand1a, rand1b: Random Values not equal");
        assertEq(rand1a, rand1c, "rand1a, rand1c: Random Values not equal");
    }

    function testStreamedSeedValues() public {
        // Set the delay to 2. This is the default. Setting it here means that the test
        // won't break even if the default changes.
        vm.prank(randomAdmin);
        randomSeedProvider.setOnChainDelay(2);

        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        vm.roll(block.number + 1);
        (uint256 randomRequestId2, address source2) = randomSeedProvider.requestRandomSeed();
        vm.roll(block.number + 1);
        (uint256 randomRequestId3, address source3) = randomSeedProvider.requestRandomSeed();
        vm.roll(block.number + 1);
        (uint256 randomRequestId4, address source4) = randomSeedProvider.requestRandomSeed();
        bytes32 rand1 = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        vm.roll(block.number + 1);
        (uint256 randomRequestId5, address source5) = randomSeedProvider.requestRandomSeed();
        bytes32 rand2 = randomSeedProvider.getRandomSeed(randomRequestId2, source2);
        vm.roll(block.number + 1);
        bytes32 rand3 = randomSeedProvider.getRandomSeed(randomRequestId3, source3);
        vm.roll(block.number + 1);
        bytes32 rand4 = randomSeedProvider.getRandomSeed(randomRequestId4, source4);
        vm.roll(block.number + 1);
        bytes32 rand5 = randomSeedProvider.getRandomSeed(randomRequestId5, source5);

        assertNotEq(rand1, bytes32(0), "rand1 is zero");
        assertNotEq(rand2, bytes32(0), "rand2 is zero");
        assertNotEq(rand3, bytes32(0), "rand3 is zero");
        assertNotEq(rand4, bytes32(0), "rand4 is zero");
        assertNotEq(rand5, bytes32(0), "rand5 is zero");
        assertNotEq(rand1, rand2, "should be different");
        assertNotEq(rand1, rand3, "should be different");
        assertNotEq(rand1, rand4, "should be different");
        assertNotEq(rand1, rand5, "should be different");
        assertNotEq(rand4, rand5, "should be different");
    }

    function testBlock256Plus() public {
        vm.roll(block.number + 1000);
        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        vm.roll(randomRequestId1 + 1);
        bytes32 rand1 = randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        assertNotEq(rand1, bytes32(0), "rand1 is zero");
    }

    function testMissedSeed() public {
        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        // Don't fulfil the value for more than 256 blocks after the fulfillment block.
        vm.roll(randomRequestId1 + 256);
        vm.expectRevert(abi.encodeWithSelector(RandomSeedProvider.GenerationFailedTryAgain.selector, randomRequestId1));
        randomSeedProvider.getRandomSeed(randomRequestId1, source1);
    }

    function testGenerateNextSeedOnChain() public {
        (uint256 lastBlock, uint256 queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, 0, "last block");
        assertEq(queueLen, 0, "queue len");

        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        (lastBlock, queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, 0, "last block");
        assertEq(queueLen, 1, "queue len");

        // Note request in the same block
        (uint256 randomRequestId2, address source2) = randomSeedProvider.requestRandomSeed();
        (lastBlock, queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, 0, "last block");
        assertEq(queueLen, 1, "queue len");

        vm.roll(randomRequestId2 + 1);
        (uint256 randomRequestId3, address source3) = randomSeedProvider.requestRandomSeed();
        (lastBlock, queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, 0, "last block");
        assertEq(queueLen, 2, "queue len");
        randomSeedProvider.getRandomSeed(randomRequestId1, source1);
        randomSeedProvider.getRandomSeed(randomRequestId2, source2);

        randomSeedProvider.generateNextSeedOnChain();
        (lastBlock, queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, block.number, "last block");
        // It is too soon for randomRequestId3, so only 1 and 2 are fulfilled.
        assertEq(queueLen, 1, "queue len");

        vm.roll(randomRequestId3 + 1);
        randomSeedProvider.generateNextSeedOnChain();
        (lastBlock, queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, block.number, "last block");
        assertEq(queueLen, 0, "queue len");
        randomSeedProvider.getRandomSeed(randomRequestId2, source2);
        randomSeedProvider.getRandomSeed(randomRequestId3, source3);
    }

    function testGenerateNextSeedOnChainLate() public {
        (uint256 randomRequestId1, address source1) = randomSeedProvider.requestRandomSeed();
        vm.roll(randomRequestId1 + 256);
        // It is not too late to fulfil the request
        vm.expectEmit(true, true, true, true);
        emit TooLateToGenerateRandom(randomRequestId1);
        randomSeedProvider.generateNextSeedOnChain();
        (uint256 lastBlock, uint256 queueLen) = randomSeedProvider.onchainGenerationStatus();
        assertEq(lastBlock, block.number, "last block");
        assertEq(queueLen, 0, "queue len");
        vm.expectRevert(abi.encodeWithSelector(RandomSeedProvider.GenerationFailedTryAgain.selector, randomRequestId1));
        randomSeedProvider.getRandomSeed(randomRequestId1, source1);
    }
}

contract SwitchingRandomSeedProviderTest is UninitializedRandomSeedProviderTest {
    MockOffchainSource public offchainSource = new MockOffchainSource();
    MockOffchainSource public offchainSource2 = new MockOffchainSource();

    function testSwitchOnchainOffchain() public {
        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        (uint256 fulfillmentIndex1, address source1) = randomSeedProvider.requestRandomSeed();
        assertEq(source1, ONCHAIN, "source");
        assertEq(fulfillmentIndex1, block.number + STANDARD_ONCHAIN_DELAY, "index");
        vm.roll(fulfillmentIndex1 + 1);
        bytes32 seed1 = randomSeedProvider.getRandomSeed(fulfillmentIndex1, source1);

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex2, address source2) = randomSeedProvider.requestRandomSeed();
        assertEq(source2, address(offchainSource), "offchain source");
        assertEq(fulfillmentIndex2, 1000, "index");

        offchainSource.setIsReady(true);
        bytes32 seed2 = randomSeedProvider.getRandomSeed(fulfillmentIndex2, source2);

        bytes32 seed1a = randomSeedProvider.getRandomSeed(fulfillmentIndex1, source1);

        assertEq(seed1, seed1a, "Seed still available");
        assertNotEq(seed1, seed2, "Must be different");
    }

    function testSwitchOffchainOffchain() public {
        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex1, address source1) = randomSeedProvider.requestRandomSeed();
        assertEq(source1, address(offchainSource), "offchain source");
        assertEq(fulfillmentIndex1, 1000, "index");
        RandomSeedProvider.SeedRequestStatus status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex1, source1);
        assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.IN_PROGRESS), "Should not be ready yet1");

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource2));

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex2, address source2) = randomSeedProvider.requestRandomSeed();
        assertEq(source2, address(offchainSource2), "offchain source 2");
        assertEq(fulfillmentIndex2, 1000, "index");

        offchainSource.setIsReady(true);
        status = randomSeedProvider.isRandomSeedReady(fulfillmentIndex1, source1);
        assertEq(uint256(status), uint256(RandomSeedProvider.SeedRequestStatus.READY), "Should be ready");

        randomSeedProvider.getRandomSeed(fulfillmentIndex1, source1);
        offchainSource2.setIsReady(true);
        randomSeedProvider.getRandomSeed(fulfillmentIndex2, source2);
    }


    function testSwitchOffchainOnchain() public {
        address aConsumer = makeAddr("aConsumer");
        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(aConsumer);

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(offchainSource));

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex1, address source1) = randomSeedProvider.requestRandomSeed();
        assertEq(source1, address(offchainSource), "offchain source");
        assertEq(fulfillmentIndex1, 1000, "index");

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(ONCHAIN);

        vm.prank(aConsumer);
        (uint256 fulfillmentIndex2, address source2) = randomSeedProvider.requestRandomSeed();
        assertEq(source2, ONCHAIN, "on chain");
        assertEq(fulfillmentIndex2, block.number + STANDARD_ONCHAIN_DELAY, "index");

        offchainSource.setIsReady(true);
        randomSeedProvider.getRandomSeed(fulfillmentIndex1, source1);

        vm.roll(fulfillmentIndex2 + 1);
        randomSeedProvider.getRandomSeed(fulfillmentIndex2, source2);
    }
}

