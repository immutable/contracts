pragma solidity 0.8.20;

import "forge-std/Test.sol";

import {MockWallet} from "../../contracts/mocks/MockWallet.sol";
import {MockWalletFactory} from "../../contracts/mocks/MockWalletFactory.sol";
import {MockFactory} from "../../contracts/mocks/MockFactory.sol";
import {ImmutableERC721MintByID} from "../../contracts/token/erc721/preset/ImmutableERC721MintByID.sol";
import {IImmutableERC721Errors} from "../../contracts/errors/Errors.sol";
import {OperatorAllowlistEnforcementErrors} from "../../contracts/errors/Errors.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {Sign} from "../utils/Sign.sol";
import {DeployOperatorAllowlist} from "../utils/DeployAllowlistProxy.sol";
import {DeploySCWallet} from "../utils/DeploySCW.sol";
import {DeployMockMarketPlace} from "../utils/DeployMockMarketPlace.sol";
import {MockMarketplace} from "../../contracts/mocks/MockMarketplace.sol";
import {MockDisguisedEOA} from "../../contracts/mocks/MockDisguisedEOA.sol";
import {MockOnReceive} from "../../contracts/mocks/MockOnReceive.sol";

contract AllowlistERC721TransferApprovals is Test {
    OperatorAllowlistUpgradeable public allowlist;
    ImmutableERC721MintByID public immutableERC721MintByID;
    DeploySCWallet public deploySCWScript;
    DeployMockMarketPlace public deployMockMarketPlaceScript;
    MockMarketplace public mockMarketPlace;
    MockFactory mockEOAFactory;

    uint256 feeReceiverKey = 1;

    address public admin = makeAddr("roleAdmin");
    address public upgrader = makeAddr("roleUpgrader");
    address public registrar = makeAddr("roleRegisterar");
    address public scwOwner = makeAddr("scwOwner");
    address public minter = makeAddr("minter");

    address feeReceiver = vm.addr(feeReceiverKey);
    address proxyAddr;
    address nonAuthorizedWallet;
    address scwAddr;
    address scwModuleAddr;

    function setUp() public {
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        proxyAddr = deployScript.run(admin, upgrader, registrar);

        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        immutableERC721MintByID = new ImmutableERC721MintByID(
            admin, "test", "USDC", "test-base-uri", "test-contract-uri", address(allowlist), feeReceiver, 0
        );

        mockEOAFactory = new MockFactory();

        nonAuthorizedWallet = address(0x2);

        deploySCWScript = new DeploySCWallet();

        deployMockMarketPlaceScript = new DeployMockMarketPlace();
        mockMarketPlace = deployMockMarketPlaceScript.run(address(immutableERC721MintByID));

        _giveMinterRole();
    }

    function testDeployment() public {
        assertEq(address(immutableERC721MintByID.operatorAllowlist()), proxyAddr);
    }

    function _addSCWAddressAllowListAndApprove(address _address) private {
        vm.startPrank(registrar);
        allowlist.addWalletToAllowlist(_address);
        immutableERC721MintByID.setApprovalForAll(_address, true);
        vm.stopPrank();
    }

    function _giveMinterRole() public {
        vm.prank(admin);
        immutableERC721MintByID.grantMinterRole(minter);
        bytes32 minterRole = immutableERC721MintByID.MINTER_ROLE();
        assertTrue(immutableERC721MintByID.hasRole(minterRole, minter));
    }

    function testShouldNotApproveNoneOALSCW() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, scwModuleAddr) = deploySCWScript.run(salt);

        vm.prank(minter);
        immutableERC721MintByID.safeMint(admin, 1);

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("ApproveTargetNotInAllowlist(address)", scwAddr));
        immutableERC721MintByID.setApprovalForAll(scwAddr, true);

        vm.expectRevert(abi.encodeWithSignature("ApproveTargetNotInAllowlist(address)", scwAddr));
        immutableERC721MintByID.approve(scwAddr, 1);
        vm.stopPrank();
    }

    function testShouldNotAllowApproveFromNoneOALContract() public {
        vm.startPrank(minter);
        immutableERC721MintByID.mint(address(mockMarketPlace), 1);
        vm.expectRevert(abi.encodeWithSignature("ApproverNotInAllowlist(address)", address(mockMarketPlace)));
        mockMarketPlace.executeApproveForAll(minter, true);
        vm.stopPrank();
    }

    function testShouldApproveEOA() public {
        vm.startPrank(minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.safeMint(minter, 2);

        immutableERC721MintByID.approve(admin, 1);
        assertEq(immutableERC721MintByID.getApproved(1), admin);
        immutableERC721MintByID.setApprovalForAll(admin, true);
        assertTrue(immutableERC721MintByID.isApprovedForAll(minter, admin));
        vm.stopPrank();
    }

    function testShouldApproveWalletInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr,) = deploySCWScript.run(salt);

        vm.prank(registrar);
        allowlist.addWalletToAllowlist(scwAddr);

        vm.startPrank(minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.safeMint(minter, 2);
        immutableERC721MintByID.approve(scwAddr, 1);
        assertEq(immutableERC721MintByID.getApproved(1), scwAddr);
        immutableERC721MintByID.setApprovalForAll(scwAddr, true);
        assertTrue(immutableERC721MintByID.isApprovedForAll(minter, scwAddr));
        vm.stopPrank();
    }

    function testShouldApproveAddrInOAL() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(mockMarketPlace);

        vm.prank(registrar);
        allowlist.addAddressesToAllowlist(addressTargets);

        vm.startPrank(minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.safeMint(minter, 2);
        immutableERC721MintByID.approve(address(mockMarketPlace), 1);
        assertEq(immutableERC721MintByID.getApproved(1), address(mockMarketPlace));
        immutableERC721MintByID.setApprovalForAll(address(mockMarketPlace), true);
        assertTrue(immutableERC721MintByID.isApprovedForAll(minter, address(mockMarketPlace)));
        vm.stopPrank();
    }

    function testTransferBetweenEOAs() public {
        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.approve(admin, 1);
        immutableERC721MintByID.transferFrom(minter, admin, 1);
        assertEq(immutableERC721MintByID.ownerOf(1), admin);
        vm.stopPrank();
    }

    function testBlockTransferForNoneOALWallet() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr,) = deploySCWScript.run(salt);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", scwAddr));
        immutableERC721MintByID.transferFrom(minter, scwAddr, 1);
        vm.stopPrank();
    }

    function testBlockTransferFromNoneOALAddress() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(mockMarketPlace);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.mint(address(mockMarketPlace), 1);
        vm.expectRevert(abi.encodeWithSignature("CallerNotInAllowlist(address)", address(mockMarketPlace)));
        mockMarketPlace.executeTransferFrom(address(mockMarketPlace), minter, 1);
        vm.stopPrank();
    }

    function testBlockTransferForNoneOALAddr() public {
        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", address(mockMarketPlace)));
        immutableERC721MintByID.transferFrom(minter, address(mockMarketPlace), 1);
        vm.stopPrank();
    }

    function testTransferToAddrInOAL() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(mockMarketPlace);

        vm.prank(registrar);
        allowlist.addAddressesToAllowlist(addressTargets);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.transferFrom(minter, address(mockMarketPlace), 1);
        assertEq(immutableERC721MintByID.ownerOf(1), address(mockMarketPlace));
        vm.stopPrank();
    }

    function testTransferToWalletInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr,) = deploySCWScript.run(salt);

        vm.prank(registrar);
        allowlist.addWalletToAllowlist(scwAddr);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        immutableERC721MintByID.transferFrom(minter, scwAddr, 1);
        assertEq(immutableERC721MintByID.ownerOf(1), scwAddr);
        vm.stopPrank();
    }

    function testTransferBetweenSCWInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (address scwAddr1,) = deploySCWScript.run(salt);
        MockWallet scw1 = MockWallet(scwAddr1);

        bytes32 salt2 = keccak256(abi.encodePacked("0x5678"));
        (address scwAddr2,) = deploySCWScript.run(salt2);

        vm.startPrank(registrar);
        allowlist.addWalletToAllowlist(scwAddr1);
        allowlist.addWalletToAllowlist(scwAddr2);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(scwAddr1, 1);
        scw1.transferNFT(address(immutableERC721MintByID), scwAddr1, scwAddr2, 1);
        assertEq(immutableERC721MintByID.ownerOf(1), scwAddr2);
        vm.stopPrank();
    }

    function testDisguisedEOAApprovalTransfer() public {
        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));

        address create2Addr = mockEOAFactory.computeMockDisguisedEOAAddress(immutableERC721MintByID, salt);

        immutableERC721MintByID.setApprovalForAll(create2Addr, true);
        mockEOAFactory.deployMockEOAWithERC721Address(immutableERC721MintByID, salt);

        assertTrue(immutableERC721MintByID.isApprovedForAll(minter, create2Addr));

        MockDisguisedEOA disguisedEOA = MockDisguisedEOA(create2Addr);

        vm.expectRevert(abi.encodeWithSignature("CallerNotInAllowlist(address)", create2Addr));
        disguisedEOA.executeTransfer(minter, admin, 1);
        vm.stopPrank();
    }

    // Here the malicious contract attempts to transfer the token out of the contract by calling transferFrom in onERC721Received
    // However, sending to the contract will fail as the contract is not in the allowlist.
    function testOnReceiveTransferFrom() public {
        MockOnReceive onReceive = new MockOnReceive(immutableERC721MintByID, admin);

        vm.startPrank(minter, minter);
        immutableERC721MintByID.safeMint(minter, 1);
        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", address(onReceive)));
        immutableERC721MintByID.safeTransferFrom(minter, address(onReceive), 1, "");
        vm.stopPrank();
    }
}
