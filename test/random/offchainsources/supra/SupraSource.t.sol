// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockSupraRouter} from "./MockSupraRouter.sol";
import {MockGame, RandomValues} from "../../MockGame.sol";
import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";
import {IOffchainRandomSource} from "contracts/random/offchainsources/IOffchainRandomSource.sol";
import {SupraSourceAdaptor, SourceAdaptorBase} from "contracts/random/offchainsources/supra/SupraSourceAdaptor.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SupraTests is Test {
    error NotVrfContract();

    bytes32 public constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

    ERC1967Proxy public proxy;
    RandomSeedProvider public impl;
    RandomSeedProvider public randomSeedProvider;

    MockSupraRouter public mockSupraRouter;
    SupraSourceAdaptor public supraSourceAdaptor;

    address public roleAdmin;
    address public randomAdmin;
    address public configAdmin;
    address public upgradeAdmin;

    address public subscription = address(0x123);

    bytes32 public constant RAND1 = bytes32(uint256(0x1a));
    bytes32 public constant RAND2 = bytes32(uint256(0x1b));

    function setUp() public virtual {
        roleAdmin = makeAddr("roleAdmin");
        randomAdmin = makeAddr("randomAdmin");
        configAdmin = makeAddr("configAdmin");
        upgradeAdmin = makeAddr("upgradeAdmin");

        impl = new RandomSeedProvider();
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSelector(RandomSeedProvider.initialize.selector, roleAdmin, randomAdmin, upgradeAdmin, false)
        );
        randomSeedProvider = RandomSeedProvider(address(proxy));

        mockSupraRouter = new MockSupraRouter();
        supraSourceAdaptor = new SupraSourceAdaptor(
            roleAdmin, configAdmin, address(mockSupraRouter), address(randomSeedProvider), subscription);
        mockSupraRouter.setAdaptor(address(supraSourceAdaptor));

        vm.prank(randomAdmin);
        randomSeedProvider.setOffchainRandomSource(address(supraSourceAdaptor));

        // Ensure we are on a new block number when we start the tests. In particular, don't
        // be on the same block number as when the contracts were deployed.
        vm.roll(block.number + 1);
    }
}

contract SupraInitTests is SupraTests {
    function testInit() public {
        mockSupraRouter = new MockSupraRouter();
        supraSourceAdaptor = new SupraSourceAdaptor(
            roleAdmin, configAdmin, address(mockSupraRouter), address(randomSeedProvider), subscription);

        assertEq(address(supraSourceAdaptor.vrfCoordinator()), address(mockSupraRouter), "vrfCoord not set correctly");
        assertEq(supraSourceAdaptor.subscriptionAccount(), subscription, "Subscription account did not match");
        assertTrue(supraSourceAdaptor.hasRole(CONFIG_ADMIN_ROLE, configAdmin), "Role config admin");
    }
}


contract SupraControlTests is SupraTests {
    event SubscriptionChange(address _newSubscription);

    function testRoleAdmin() public {
        bytes32 role = CONFIG_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");

        vm.prank(roleAdmin);
        supraSourceAdaptor.grantRole(role, newAdmin);
        assertTrue(supraSourceAdaptor.hasRole(role, newAdmin));
    }

    function testRoleAdminBadAuth() public {
        bytes32 role = CONFIG_ADMIN_ROLE;
        address newAdmin = makeAddr("newAdmin");
        vm.expectRevert();
        supraSourceAdaptor.grantRole(role, newAdmin);
    }

    function testSetSubscription() public {
        address newSub = address(7);

        vm.prank(configAdmin);
        vm.expectEmit(true, true, true, true);
        emit SubscriptionChange(newSub);
        supraSourceAdaptor.setSubscription(newSub);
        assertEq(supraSourceAdaptor.subscriptionAccount(), newSub, "subscription not set correctly");
    }

    function testSetSubscriptionBadAuth() public {
        address newSub = address(7);

        vm.expectRevert();
        supraSourceAdaptor.setSubscription(newSub);
    }
}


contract SupraOperationalTests is SupraTests {
    error OffchainWaitForRandom();
    error UnexpectedRandomWordsLength(uint256 _length);

    event RequestId(uint256 _requestId);

    function testRequestRandom() public {
        vm.recordLogs();
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex = supraSourceAdaptor.requestOffchainRandom();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics[0], keccak256("RequestId(uint256)"));
        uint256 requestId = abi.decode(entries[0].data, (uint256));
        assertEq(fulfilmentIndex, requestId, "Must be the same");

        bool ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex);
        assertFalse(ready, "Should not be ready yet");

        mockSupraRouter.sendFulfill(fulfilmentIndex, uint256(RAND1));

        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex);
        assertTrue(ready, "Should be ready");

        vm.prank(address(randomSeedProvider));
        bytes32 rand = supraSourceAdaptor.getOffchainRandom(fulfilmentIndex);
        assertEq(rand, RAND1, "Wrong value returned");
    }

    function testTwoRequests() public {
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex1 = supraSourceAdaptor.requestOffchainRandom();
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex2 = supraSourceAdaptor.requestOffchainRandom();
        assertNotEq(fulfilmentIndex1, fulfilmentIndex2, "Different requests receive different indices");

        bool ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertFalse(ready, "Should not be ready yet1");
        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertFalse(ready, "Should not be ready yet2");

        mockSupraRouter.sendFulfill(fulfilmentIndex2, uint256(RAND2));
        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertFalse(ready, "Should not be ready yet3");
        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertTrue(ready, "Should be ready1");

        vm.prank(address(randomSeedProvider));
        bytes32 rand = supraSourceAdaptor.getOffchainRandom(fulfilmentIndex2);
        assertEq(rand, RAND2, "Wrong value returned1");

        mockSupraRouter.sendFulfill(fulfilmentIndex1, uint256(RAND1));
        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex1);
        assertTrue(ready, "Should be ready2");
        ready = supraSourceAdaptor.isOffchainRandomReady(fulfilmentIndex2);
        assertTrue(ready, "Should be ready3");

        vm.prank(address(randomSeedProvider));
        rand = supraSourceAdaptor.getOffchainRandom(fulfilmentIndex1);
        assertEq(rand, RAND1, "Wrong value returned2");
    }

    function testBadFulfilment() public {
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex = supraSourceAdaptor.requestOffchainRandom();

        uint256 length = 2;
        uint256[] memory randomWords = new uint256[](length);
        randomWords[0] = uint256(RAND1);

        vm.expectRevert(abi.encodeWithSelector(UnexpectedRandomWordsLength.selector, length));
        mockSupraRouter.sendFulfillRaw(fulfilmentIndex, randomWords);
    }

    function testRequestTooEarly() public {
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex = supraSourceAdaptor.requestOffchainRandom();

        vm.prank(address(randomSeedProvider));
        vm.expectRevert(abi.encodeWithSelector(OffchainWaitForRandom.selector));
        supraSourceAdaptor.getOffchainRandom(fulfilmentIndex);
    }

    function testHackFulfilment() public {
        vm.prank(address(randomSeedProvider));
        uint256 fulfilmentIndex = supraSourceAdaptor.requestOffchainRandom();

        MockSupraRouter hackSupraRouter = new MockSupraRouter();
        hackSupraRouter.setAdaptor(address(supraSourceAdaptor));

        vm.expectRevert(abi.encodeWithSelector(NotVrfContract.selector));
        hackSupraRouter.sendFulfill(fulfilmentIndex, uint256(RAND1));
    }

    function testRequestBadAuth() public {
        vm.prank(configAdmin);
        vm.expectRevert(abi.encodeWithSelector(SourceAdaptorBase.NotRandomSeedProvider.selector, configAdmin));
        supraSourceAdaptor.requestOffchainRandom();
    }
}



contract SupraIntegrationTests is SupraTests {
    function testEndToEnd() public {
        MockGame game = new MockGame(address(randomSeedProvider));

        vm.prank(randomAdmin);
        randomSeedProvider.addOffchainRandomConsumer(address(game));

        vm.recordLogs();
        uint256 randomRequestId = game.requestRandomValueCreation(1);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Unexpected number of events emitted");
        assertEq(entries[0].topics[0], keccak256("RequestId(uint256)"));
        uint256 fulfilmentIndex = abi.decode(entries[0].data, (uint256));

        assertEq(
            uint256(game.isRandomValueReady(randomRequestId)),
            uint256(RandomValues.RequestStatus.IN_PROGRESS),
            "Should not be ready yet"
        );

        mockSupraRouter.sendFulfill(fulfilmentIndex, uint256(RAND1));

        assertEq(
            uint256(game.isRandomValueReady(randomRequestId)),
            uint256(RandomValues.RequestStatus.READY),
            "Should be ready"
        );

        bytes32[] memory randomValue = game.fetchRandomValues(randomRequestId);
        assertEq(randomValue.length, 1, "length");
        assertNotEq(randomValue[0], bytes32(0), "Random Value zero");
    }
}

contract SupraCoverageFakeTests is SupraTests {
    // Do calls to unused functions in MockSupraRouter so that it doesn't impact the coverage results.
    function testFixMockCoordinatorCoverage() public {
        mockSupraRouter = new MockSupraRouter();
        mockSupraRouter.setAdaptor(address(supraSourceAdaptor));
        string memory str = "";
        mockSupraRouter.generateRequest(
            str,
            uint8(0), /* _rngCount */
            uint256(0), /* _numConfirmations */
            uint256(0), /* _clientSeed */
            address(0) /* _clientWalletAddress */
        );
    }
}
