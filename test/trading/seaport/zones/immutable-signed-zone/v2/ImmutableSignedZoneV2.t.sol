// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ReceivedItem, Schema, SpentItem, ZoneParameters} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ImmutableSignedZoneV2} from
    "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/ImmutableSignedZoneV2.sol";
import {SIP5EventsAndErrors} from
    "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/interfaces/SIP5EventsAndErrors.sol";
import {SIP6EventsAndErrors} from
    "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/interfaces/SIP6EventsAndErrors.sol";
import {SIP7EventsAndErrors} from
    "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/interfaces/SIP7EventsAndErrors.sol";
import {ZoneAccessControlEventsAndErrors} from
    "../../../../../../contracts/trading/seaport/zones/immutable-signed-zone/v2/interfaces/ZoneAccessControlEventsAndErrors.sol";
import {SigningTestHelper} from "../../../utils/SigningTestHelper.t.sol";
import {ImmutableSignedZoneV2Harness} from "./ImmutableSignedZoneV2Harness.t.sol";

// solhint-disable func-name-mixedcase

contract ImmutableSignedZoneV2Test is
    Test,
    SigningTestHelper,
    ZoneAccessControlEventsAndErrors,
    SIP5EventsAndErrors,
    SIP6EventsAndErrors,
    SIP7EventsAndErrors
{
    // solhint-disable private-vars-leading-underscore
    address private immutable OWNER = makeAddr("owner");
    address private immutable FULFILLER = makeAddr("fulfiller");
    address private immutable OFFERER = makeAddr("offerer");
    address private immutable SIGNER;
    uint256 private immutable SIGNER_PRIVATE_KEY;
    // solhint-enable private-vars-leading-underscore

    // OpenZeppelin v5 access/IAccessControl.sol
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();

    constructor() {
        (SIGNER, SIGNER_PRIVATE_KEY) = makeAddrAndKey("signer");
    }

    /* constructor */

    function test_contructor_grantsAdminRoleToOwner() public {
        address owner = makeAddr("owner");
        ImmutableSignedZoneV2 zone = new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
        bool ownerHasAdminRole = zone.hasRole(zone.DEFAULT_ADMIN_ROLE(), owner);
        assertTrue(ownerHasAdminRole);
    }

    function test_contructor_emitsSeaportCompatibleContractDeployedEvent() public {
        vm.expectEmit();
        emit SeaportCompatibleContractDeployed();
        new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            makeAddr("owner")
        );
    }

    /* grantRole */

    function test_grantRole_revertsIfCalledByNonAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        address nonAdmin = makeAddr("non_admin");
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, nonAdmin, zone.DEFAULT_ADMIN_ROLE())
        );
        vm.prank(nonAdmin);
        zone.grantRole(managerRole, OWNER);
    }

    function test_grantRole_grantsIfCalledByAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        address newManager = makeAddr("new_manager");
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, newManager);
        bool newManagerHasManagerRole = zone.hasRole(managerRole, newManager);
        assertTrue(newManagerHasManagerRole);
    }

    /* revokeRole */

    function test_revokeRole_revertsIfCalledByNonAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        address managerOne = makeAddr("manager_one");
        address managerTwo = makeAddr("manager_two");
        vm.prank(OWNER);
        zone.grantRole(managerRole, managerOne);
        vm.prank(OWNER);
        zone.grantRole(managerRole, managerTwo);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, managerOne, zone.DEFAULT_ADMIN_ROLE())
        );
        vm.prank(managerOne);
        zone.revokeRole(managerRole, managerTwo);
    }

    function test_revokeRole_revertsIfRevokingLastDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 adminRole = zone.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(abi.encodeWithSelector(LastDefaultAdminRole.selector, OWNER));
        vm.prank(OWNER);
        zone.revokeRole(adminRole, OWNER);
    }

    function test_revokeRole_revokesIfRevokingNonLastDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 adminRole = zone.DEFAULT_ADMIN_ROLE();
        address newAdmin = makeAddr("new_admin");
        vm.prank(OWNER);
        zone.grantRole(adminRole, newAdmin);
        vm.prank(OWNER);
        zone.revokeRole(adminRole, OWNER);
        bool ownerHasAdminRole = zone.hasRole(adminRole, OWNER);
        assertFalse(ownerHasAdminRole);
    }

    function test_revokeRole_revokesIfRevokingLastNonDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.revokeRole(managerRole, OWNER);
        bool ownerHasManagerRole = zone.hasRole(managerRole, OWNER);
        uint256 managerCount = zone.getRoleMemberCount(managerRole);
        assertFalse(ownerHasManagerRole);
        assertEq(managerCount, 0);
    }

    /* renounceRole */

    function test_renounceRole_revertsIfCallerDoesNotMatchCallerConfirmationAddress() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        address newManager = makeAddr("new_manager");
        vm.prank(OWNER);
        zone.grantRole(managerRole, newManager);
        vm.expectRevert(abi.encodeWithSelector(AccessControlBadConfirmation.selector));
        vm.prank(newManager);
        zone.renounceRole(managerRole, makeAddr("random"));
    }

    function test_renounceRole_revertsIfRenouncingLastDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 adminRole = zone.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(abi.encodeWithSelector(LastDefaultAdminRole.selector, OWNER));
        vm.prank(OWNER);
        zone.renounceRole(adminRole, OWNER);
    }

    function test_renounceRole_revokesIfRenouncingNonLastDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 adminRole = zone.DEFAULT_ADMIN_ROLE();
        address newAdmin = makeAddr("new_admin");
        vm.prank(OWNER);
        zone.grantRole(adminRole, newAdmin);
        vm.prank(OWNER);
        zone.renounceRole(adminRole, OWNER);
        bool ownerHasAdminRole = zone.hasRole(adminRole, OWNER);
        assertFalse(ownerHasAdminRole);
    }

    function test_renounceRole_revokesIfRenouncingLastNonDefaultAdminRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.renounceRole(managerRole, OWNER);
        bool ownerHasManagerRole = zone.hasRole(managerRole, OWNER);
        uint256 managerCount = zone.getRoleMemberCount(managerRole);
        assertFalse(ownerHasManagerRole);
        assertEq(managerCount, 0);
    }

    /* addSigner */

    function test_addSigner_revertsIfCalledByNonZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, OWNER, zone.ZONE_MANAGER_ROLE())
        );
        vm.prank(OWNER);
        zone.addSigner(makeAddr("signer_to_add"));
    }

    function test_addSigner_revertsIfSignerIsTheZeroAddress() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.expectRevert(abi.encodeWithSelector(SignerCannotBeZeroAddress.selector));
        vm.prank(OWNER);
        zone.addSigner(address(0));
    }

    function test_addSigner_emitsSignerAddedEvent() public {
        address signerToAdd = makeAddr("signer_to_add");
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.expectEmit(address(zone));
        emit SignerAdded(signerToAdd);
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerAlreadyActive() public {
        address signerToAdd = makeAddr("signer_to_add");
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerAlreadyActive.selector, signerToAdd));
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    function test_addSigner_revertsIfSignerWasPreviouslyActive() public {
        address signerToAdd = makeAddr("signer_to_add");
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
        vm.prank(OWNER);
        zone.removeSigner(signerToAdd);
        vm.expectRevert(abi.encodeWithSelector(SignerCannotBeReauthorized.selector, signerToAdd));
        vm.prank(OWNER);
        zone.addSigner(signerToAdd);
    }

    /* removeSigner */

    function test_removeSigner_revertsIfCalledByNonZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, OWNER, zone.ZONE_MANAGER_ROLE())
        );
        vm.prank(OWNER);
        zone.removeSigner(makeAddr("signer_to_remove"));
    }

    function test_removeSigner_revertsIfSignerNotActive() public {
        address signerToRemove = makeAddr("signer_to_remove");
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.expectRevert(abi.encodeWithSelector(SignerNotActive.selector, signerToRemove));
        vm.prank(OWNER);
        zone.removeSigner(signerToRemove);
    }

    function test_removeSigner_emitsSignerRemovedEvent() public {
        address signerToRemove = makeAddr("signer_to_remove");
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.addSigner(signerToRemove);
        vm.expectEmit(address(zone));
        emit SignerRemoved(signerToRemove);
        vm.prank(OWNER);
        zone.removeSigner(signerToRemove);
    }

    /* updateAPIEndpoint */

    function test_updateAPIEndpoint_revertsIfCalledByNonZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, OWNER, zone.ZONE_MANAGER_ROLE())
        );
        vm.prank(OWNER);
        zone.updateAPIEndpoint("https://www.new-immutable.com");
    }

    function test_updateAPIEndpoint_updatesAPIEndpointIfCalledByZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        string memory expectedApiEndpoint = "https://www.new-immutable.com";
        vm.prank(OWNER);
        zone.updateAPIEndpoint(expectedApiEndpoint);
        (, Schema[] memory schemas) = zone.getSeaportMetadata();
        (, string memory apiEndpoint,,) = abi.decode(schemas[0].metadata, (bytes32, string, uint256[], string));
        assertEq(apiEndpoint, expectedApiEndpoint);
    }

    /* updateDocumentationURI */

    function test_updateDocumentationURI_revertsIfCalledByNonZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, OWNER, zone.ZONE_MANAGER_ROLE())
        );
        vm.prank(OWNER);
        zone.updateDocumentationURI("https://www.new-immutable.com/docs");
    }

    function test_updateDocumentationURI_updatesDocumentationURIIfCalledByZoneManagerRole() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        string memory expectedDocumentationURI = "https://www.new-immutable.com/docs";
        vm.prank(OWNER);
        zone.updateDocumentationURI(expectedDocumentationURI);
        (, Schema[] memory schemas) = zone.getSeaportMetadata();
        (,,, string memory documentationURI) = abi.decode(schemas[0].metadata, (bytes32, string, uint256[], string));
        assertEq(documentationURI, expectedDocumentationURI);
    }

    /* getSeaportMetadata */

    function test_getSeaportMetadata() public {
        string memory expectedZoneName = "MyZoneName";
        string memory expectedApiEndpoint = "https://www.immutable.com";
        string memory expectedDocumentationURI = "https://www.immutable.com/docs";

        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            expectedZoneName,
            expectedApiEndpoint,
            expectedDocumentationURI,
            OWNER
        );

        bytes32 expectedDomainSeparator = zone.exposed_deriveDomainSeparator();
        uint256[] memory expectedSubstandards = zone.exposed_getSupportedSubstandards();

        (string memory name, Schema[] memory schemas) = zone.getSeaportMetadata();
        (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        ) = abi.decode(schemas[0].metadata, (bytes32, string, uint256[], string));

        assertEq(name, expectedZoneName);
        assertEq(schemas.length, 1);
        assertEq(schemas[0].id, 7);
        assertEq(domainSeparator, expectedDomainSeparator);
        assertEq(apiEndpoint, expectedApiEndpoint);
        assertEq(substandards, expectedSubstandards);
        assertEq(documentationURI, expectedDocumentationURI);
    }

    /* sip7Information */

    function test_sip7Information() public {
        string memory expectedApiEndpoint = "https://www.immutable.com";
        string memory expectedDocumentationURI = "https://www.immutable.com/docs";

        ImmutableSignedZoneV2Harness zone = new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            expectedApiEndpoint,
            expectedDocumentationURI,
            OWNER
        );

        bytes32 expectedDomainSeparator = zone.exposed_deriveDomainSeparator();
        uint256[] memory expectedSubstandards = zone.exposed_getSupportedSubstandards();

        (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        ) = zone.sip7Information();

        assertEq(domainSeparator, expectedDomainSeparator);
        assertEq(apiEndpoint, expectedApiEndpoint);
        assertEq(substandards, expectedSubstandards);
        assertEq(documentationURI, expectedDocumentationURI);
    }

    /* validateOrder */

    function test_validateOrder_revertsIfEmptyExtraData() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(InvalidExtraData.selector, "extraData is empty", zoneParameters.orderHash)
        );
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfExtraDataLengthIsLessThan93() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: bytes(hex"01"),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector, "extraData length must be at least 93 bytes", zoneParameters.orderHash
            )
        );
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfExtraDataVersionIsNotSupported() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: bytes(
                hex"01f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000660f3027d9ef9e6e50a74cc24433373b9cdd97693a02adcc94e562bb59a5af68190ecaea4414dcbe74618f6c77d11cbcf4a8345bbdf46e665249904925c95929ba6606638b779c6b502204fca6bb0539cdc3dc258fe3ce7b53be0c4ad620899167fedaa8"
                ),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(abi.encodeWithSelector(UnsupportedExtraDataVersion.selector, uint8(1)));
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfSignatureHasExpired() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        uint64 expiration = 100;

        bytes memory extraData =
            _buildExtraData(zone, SIGNER_PRIVATE_KEY, FULFILLER, expiration, orderHash, new bytes(0));

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: extraData,
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                SignatureExpired.selector,
                1000,
                100,
                bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9)
            )
        );
        // set current block.timestamp to be 1000
        vm.warp(1000);
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfActualFulfillerDoesNotMatchExpectedFulfiller() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        address randomFulfiller = makeAddr("random");
        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        uint64 expiration = 100;

        bytes memory extraData =
            _buildExtraData(zone, SIGNER_PRIVATE_KEY, FULFILLER, expiration, orderHash, new bytes(0));

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: randomFulfiller,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: extraData,
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidFulfiller.selector,
                FULFILLER,
                randomFulfiller,
                bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9)
            )
        );
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfSignerIsNotActive() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        uint64 expiration = 100;

        bytes memory extraData =
            _buildExtraData(zone, SIGNER_PRIVATE_KEY, FULFILLER, expiration, orderHash, new bytes(0));

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: extraData,
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(SignerNotActive.selector, address(0x6E12D8C87503D4287c294f2Fdef96ACd9DFf6bd2))
        );
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_revertsIfContextIsEmpty() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.addSigner(SIGNER);

        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        uint64 expiration = 100;

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC1155, token: address(0x5), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x4),
            identifier: 0,
            amount: 20,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        bytes memory extraData = _buildExtraDataWithoutContext(zone, SIGNER_PRIVATE_KEY, FULFILLER, expiration, orderHash);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: spentItems,
            consideration: receivedItems,
            extraData: extraData,
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        vm.expectRevert(
            abi.encodeWithSelector(InvalidExtraData.selector, "invalid context, no substandards present", zoneParameters.orderHash)
        );
        zone.validateOrder(zoneParameters);
    }

    function test_validateOrder_returnsMagicValueOnSuccessfulValidation() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        bytes32 managerRole = zone.ZONE_MANAGER_ROLE();
        vm.prank(OWNER);
        zone.grantRole(managerRole, OWNER);
        vm.prank(OWNER);
        zone.addSigner(SIGNER);

        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        uint64 expiration = 100;

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC1155, token: address(0x5), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x4),
            identifier: 0,
            amount: 20,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0xec07a42041c18889c5c5dcd348923ea9f3d0979735bd8b3b687ebda38d9b6a31);
        bytes memory substandard4Data = abi.encode(orderHashes);
        bytes memory substandard6Data = abi.encodePacked(uint256(10), substandard3Data);
        bytes memory context = abi.encodePacked(
            bytes1(0x03), substandard3Data, bytes1(0x04), substandard4Data, bytes1(0x06), substandard6Data
        );

        bytes memory extraData = _buildExtraData(zone, SIGNER_PRIVATE_KEY, FULFILLER, expiration, orderHash, context);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9),
            fulfiller: FULFILLER,
            offerer: OFFERER,
            offer: spentItems,
            consideration: receivedItems,
            extraData: extraData,
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });
        assertEq(zone.validateOrder(zoneParameters), bytes4(0x17b1f942));
    }

    /* supportsInterface */

    function test_supportsInterface() public {
        ImmutableSignedZoneV2 zone = _newZone(OWNER);
        assertTrue(zone.supportsInterface(0x01ffc9a7)); // ERC165 interface
        assertFalse(zone.supportsInterface(0xffffffff)); // ERC165 compliance
        assertTrue(zone.supportsInterface(0x2e778efc)); // SIP-5 interface
        assertTrue(zone.supportsInterface(0x3839be19)); // SIP-5 compliance - ZoneInterface
    }

    /* _domainSeparator */

    function test_domainSeparator_returnsCachedDomainSeparatorWhenChainIDMatchesValueSetOnDeployment() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32 domainSeparator = zone.exposed_domainSeparator();
        assertEq(domainSeparator, bytes32(0xafb48e1c246f21ba06352cb2c0ebe99b8adc2590dfc48fa547732df870835b42));
    }

    function test_domainSeparator_returnsUpdatedDomainSeparatorIfChainIDIsDifferentFromValueSetOnDeployment() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32 domainSeparatorCached = zone.exposed_domainSeparator();
        vm.chainId(31338);
        bytes32 domainSeparatorDerived = zone.exposed_domainSeparator();

        assertNotEq(domainSeparatorCached, domainSeparatorDerived);
        assertEq(domainSeparatorDerived, bytes32(0x835aabb0d2af048df195a75a990b42533471d4a4e82842cd54a892eaac463d74));
    }

    /* _deriveDomainSeparator */

    function test_deriveDomainSeparator_returnsDomainSeparatorForChainID() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32 domainSeparator = zone.exposed_deriveDomainSeparator();
        assertEq(domainSeparator, bytes32(0xafb48e1c246f21ba06352cb2c0ebe99b8adc2590dfc48fa547732df870835b42));
    }

    /* _getSupportedSubstandards */

    function test_getSupportedSubstandards() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        uint256[] memory supportedSubstandards = zone.exposed_getSupportedSubstandards();
        assertEq(supportedSubstandards.length, 3);
        assertEq(supportedSubstandards[0], 3);
        assertEq(supportedSubstandards[1], 4);
        assertEq(supportedSubstandards[2], 6);
    }

    /* _deriveSignedOrderHash  */

    function test_deriveSignedOrderHash_returnsHashOfSignedOrder() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        address fulfiller = 0x71458637cD221877830A21F543E8b731e93C3627;
        uint64 expiration = 1234995;
        bytes32 orderHash = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);
        bytes memory context = hex"9062b0574be745508bed2ff7f8f5057446b89d16d35980b2a26f8e4cb03ddf91";
        bytes32 derivedSignedOrderHash = zone.exposed_deriveSignedOrderHash(fulfiller, expiration, orderHash, context);
        assertEq(derivedSignedOrderHash, 0x40c87207c5a0c362da24cb974859c70655de00fee9400f3a805ac360b90bd8c5);
    }

    /* _validateSubstandards */

    function test_validateSubstandards_emptyContext() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        zone.exposed_validateSubstandards(new bytes(0), zoneParameters);
    }

    function test_validateSubstandards_substandard3() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0x7426c58179a9510d8d9f42ecb0deff6c2fdb177027f684c57f1f2795e25b433e);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data);
        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_substandard4() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(
            bytes1(0x04),
            bytes32(uint256(32)),
            bytes32(uint256(1)),
            bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9)
        );

        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_substandard6() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC721, token: address(0x2), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10));
        bytes32 substandard6Data = 0x6d0303fb2c992bf1970cab0fae2e4cd817df77741cee30dd7917b719a165af3e;
        bytes memory context = abi.encodePacked(bytes1(0x06), uint256(100), substandard6Data);

        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_multipleSubstandardsInCorrectOrder() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0x7426c58179a9510d8d9f42ecb0deff6c2fdb177027f684c57f1f2795e25b433e);
        bytes memory substandard4Data = abi.encode(orderHashes);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data, bytes1(0x04), substandard4Data);

        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_substandards3Then6() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC1155, token: address(0x5), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x4),
            identifier: 0,
            amount: 20,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0xec07a42041c18889c5c5dcd348923ea9f3d0979735bd8b3b687ebda38d9b6a31);
        bytes memory substandard6Data = abi.encodePacked(uint256(10), substandard3Data);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data, bytes1(0x06), substandard6Data);

        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_allSubstandards() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC1155, token: address(0x5), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x4),
            identifier: 0,
            amount: 20,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0xec07a42041c18889c5c5dcd348923ea9f3d0979735bd8b3b687ebda38d9b6a31);
        bytes memory substandard4Data = abi.encode(orderHashes);
        bytes memory substandard6Data = abi.encodePacked(uint256(10), substandard3Data);
        bytes memory context = abi.encodePacked(
            bytes1(0x03), substandard3Data, bytes1(0x04), substandard4Data, bytes1(0x06), substandard6Data
        );

        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    function test_validateSubstandards_revertsOnMultipleSubstandardsInIncorrectOrder() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0x7426c58179a9510d8d9f42ecb0deff6c2fdb177027f684c57f1f2795e25b433e);
        bytes memory substandard4Data = abi.encode(orderHashes);
        bytes memory context = abi.encodePacked(bytes1(0x04), substandard4Data, bytes1(0x03), substandard3Data);

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector, "invalid context, unexpected context length", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandards(context, zoneParameters);
    }

    /* _validateSubstandard3 */

    function test_validateSubstandard3_returnsZeroLengthIfNotSubstandard3() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        uint256 substandardLengthResult = zone.exposed_validateSubstandard3(hex"04", zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard3_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x03), bytes10(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector, "invalid substandard 3 data length", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard3(context, zoneParameters);
    }

    function test_validateSubstandard3_revertsIfDerivedReceivedItemsHashNotEqualToHashInContext() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x03), bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(Substandard3Violation.selector, zoneParameters.orderHash));
        zone.exposed_validateSubstandard3(context, zoneParameters);
    }

    function test_validateSubstandard3_returns33OnSuccess() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        ReceivedItem memory receivedItem = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[0] = receivedItem;

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 1, 1));
        bytes32 substandard3Data = bytes32(0x7426c58179a9510d8d9f42ecb0deff6c2fdb177027f684c57f1f2795e25b433e);
        bytes memory context = abi.encodePacked(bytes1(0x03), substandard3Data);

        uint256 substandardLengthResult = zone.exposed_validateSubstandard3(context, zoneParameters);
        assertEq(substandardLengthResult, 33);
    }

    /* _validateSubstandard4 */

    function test_validateSubstandard4_returnsZeroLengthIfNotSubstandard4() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        uint256 substandardLengthResult = zone.exposed_validateSubstandard4(hex"02", zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard4_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x04), bytes10(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector, "invalid substandard 4 data length", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard4(context, zoneParameters);
    }

    function test_validateSubstandard4_revertsIfExpectedOrderHashesAreNotPresent() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes32[] memory expectedOrderHashes = new bytes32[](1);
        expectedOrderHashes[0] = bytes32(0x17d4cf2b6c174a86b533210b50ba676a82e5ab1e2e89ea538f0a43a37f92fcbf);

        bytes memory context = abi.encodePacked(bytes1(0x04), abi.encode(expectedOrderHashes));

        vm.expectRevert(
            abi.encodeWithSelector(
                Substandard4Violation.selector,
                zoneParameters.orderHashes,
                expectedOrderHashes,
                zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard4(context, zoneParameters);
    }

    function test_validateSubstandard4_returnsLengthOfSubstandardSegmentOnSuccess() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = bytes32(0x43592598d0419e49d268e9b553427fd7ba1dd091eaa3f6127161e44afb7b40f9);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: orderHashes,
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x04), abi.encode(orderHashes));

        uint256 substandardLengthResult = zone.exposed_validateSubstandard4(context, zoneParameters);
        // bytes1 + bytes32 + bytes32 + bytes32 = 97
        assertEq(substandardLengthResult, 97);
    }

    /* _validateSubstandard6 */

    function test_validateSubstandard6_returnsZeroLengthIfNotSubstandard6() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        uint256 substandardLengthResult = zone.exposed_validateSubstandard6(hex"04", zoneParameters);
        assertEq(substandardLengthResult, 0);
    }

    function test_validateSubstandard6_revertsIfContextLengthIsInvalid() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: new SpentItem[](0),
            consideration: new ReceivedItem[](0),
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x06), bytes10(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidExtraData.selector, "invalid substandard 6 data length", zoneParameters.orderHash
            )
        );
        zone.exposed_validateSubstandard6(context, zoneParameters);
    }

    function test_validateSubstandard6_revertsIfDerivedReceivedItemsHashesIsNotEqualToHashesInContext() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC721, token: address(0x2), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        bytes memory context = abi.encodePacked(bytes1(0x06), uint256(100), bytes32(uint256(0x123456)));

        vm.expectRevert(
            abi.encodeWithSelector(Substandard6Violation.selector, spentItems[0].amount, 100, zoneParameters.orderHash)
        );
        zone.exposed_validateSubstandard6(context, zoneParameters);
    }

    function test_validateSubstandard6_returnsLengthOfSubstandardSegmentOnSuccess() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        SpentItem[] memory spentItems = new SpentItem[](1);
        spentItems[0] = SpentItem({itemType: ItemType.ERC721, token: address(0x2), identifier: 222, amount: 10});

        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });

        ZoneParameters memory zoneParameters = ZoneParameters({
            orderHash: bytes32(0),
            fulfiller: address(0x2),
            offerer: address(0x3),
            offer: spentItems,
            consideration: receivedItems,
            extraData: new bytes(0),
            orderHashes: new bytes32[](0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0)
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10));
        bytes32 substandard6Data = 0x6d0303fb2c992bf1970cab0fae2e4cd817df77741cee30dd7917b719a165af3e;
        bytes memory context = abi.encodePacked(bytes1(0x06), uint256(100), substandard6Data);

        uint256 substandardLengthResult = zone.exposed_validateSubstandard6(context, zoneParameters);
        // bytes1 + uint256 + bytes32 = 65
        assertEq(substandardLengthResult, 65);
    }

    /* _deriveReceivedItemsHash */

    function test_deriveReceivedItemsHash_returnsHashIfNoReceivedItems() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](0);

        bytes32 receivedItemsHash = zone.exposed_deriveReceivedItemsHash(receivedItems, 0, 0);
        assertEq(receivedItemsHash, bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470));
    }

    function test_deriveReceivedItemsHash_returnsHashForValidReceivedItems() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        ReceivedItem[] memory receivedItems = new ReceivedItem[](2);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });
        receivedItems[1] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 199,
            amount: 10,
            recipient: payable(address(0x3))
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10));
        bytes32 receivedItemsHash = zone.exposed_deriveReceivedItemsHash(receivedItems, 100, 10);
        assertEq(receivedItemsHash, bytes32(0x8f5c27e415d7805dea8816d4030dc2c0ce11f8f48a0adcde373021dec7b41aad));
    }

    function test_deriveReceivedItemsHash_returnsHashForReceivedItemWithAVeryLargeAmount() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);
        ReceivedItem[] memory receivedItems = new ReceivedItem[](1);
        receivedItems[0] = ReceivedItem({
            itemType: ItemType.ERC20,
            token: address(0x2),
            identifier: 222,
            amount: 10,
            recipient: payable(address(0x3))
        });

        // console.logBytes32(zone.exposed_deriveReceivedItemsHash(receivedItems, type(uint256).max, 100));
        bytes32 receivedItemsHash = zone.exposed_deriveReceivedItemsHash(receivedItems, type(uint256).max, 100);
        assertEq(receivedItemsHash, bytes32(0xdb99f7eb854f29cd6f8faedea38d7da25073ef9876653ff45ab5c10e51f8ce4f));
    }

    /* _bytes32ArrayIncludes */

    function test_bytes32ArrayIncludes_returnsFalseIfSourceArrayIsSmallerThanValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory sourceArray = new bytes32[](1);
        bytes32[] memory valuesArray = new bytes32[](2);

        bool includesEmptySource = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertFalse(includesEmptySource);
    }

    function test_bytes32ArrayIncludes_returnsFalseIfSourceArrayDoesNotIncludeValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory sourceArray = new bytes32[](2);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(3));
        valuesArray[1] = bytes32(uint256(4));

        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertFalse(includes);
    }

    function test_bytes32ArrayIncludes_returnsTrueIfSourceArrayEqualsValuesArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory sourceArray = new bytes32[](2);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(1));
        valuesArray[1] = bytes32(uint256(2));

        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertTrue(includes);
    }

    function test_bytes32ArrayIncludes_returnsTrueIfValuesArrayIsASubsetOfSourceArray() public {
        ImmutableSignedZoneV2Harness zone = _newZoneHarness(OWNER);

        bytes32[] memory sourceArray = new bytes32[](4);
        sourceArray[0] = bytes32(uint256(1));
        sourceArray[1] = bytes32(uint256(2));
        sourceArray[2] = bytes32(uint256(3));
        sourceArray[3] = bytes32(uint256(4));
        bytes32[] memory valuesArray = new bytes32[](2);
        valuesArray[0] = bytes32(uint256(1));
        valuesArray[1] = bytes32(uint256(2));

        bool includes = zone.exposed_bytes32ArrayIncludes(sourceArray, valuesArray);
        assertTrue(includes);
    }

    /* helper functions */

    function _newZone(address owner) private returns (ImmutableSignedZoneV2) {
        return new ImmutableSignedZoneV2(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
    }

    function _newZoneHarness(address owner) private returns (ImmutableSignedZoneV2Harness) {
        return new ImmutableSignedZoneV2Harness(
            "MyZoneName",
            "https://www.immutable.com",
            "https://www.immutable.com/docs",
            owner
        );
    }

    function _buildExtraData(
        ImmutableSignedZoneV2Harness zone,
        uint256 signerPrivateKey,
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes memory context
    ) private view returns (bytes memory) {
        bytes32 eip712SignedOrderHash = zone.exposed_deriveSignedOrderHash(fulfiller, expiration, orderHash, context);
        bytes memory extraData = abi.encodePacked(
            bytes1(0),
            fulfiller,
            expiration,
            _signCompact(signerPrivateKey, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash)),
            context
        );
        return extraData;
    }

    function _buildExtraDataWithoutContext(
        ImmutableSignedZoneV2Harness zone,
        uint256 signerPrivateKey,
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash
    ) private view returns (bytes memory) {
        bytes32 eip712SignedOrderHash = zone.exposed_deriveSignedOrderHash(fulfiller, expiration, orderHash, context);
        bytes memory extraData = abi.encodePacked(
            bytes1(0),
            fulfiller,
            expiration,
            _signCompact(signerPrivateKey, ECDSA.toTypedDataHash(zone.exposed_domainSeparator(), eip712SignedOrderHash))
        );
        return extraData;
    }
}

// solhint-enable func-name-mixedcase
