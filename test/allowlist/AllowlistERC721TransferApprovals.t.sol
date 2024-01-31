pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {MockWallet} from "../../contracts/mocks/MockWallet.sol";
import {MockWalletFactory} from "../../contracts/mocks/MockWalletFactory.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {IImmutableERC721Errors} from "../../contracts/errors/Errors.sol";
import {OperatorAllowlistEnforcementErrors} from "../../contracts/errors/Errors.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {Sign} from "../utils/Sign.sol";
import {DeployOperatorAllowlist} from  "../utils/DeployAllowlistProxy.sol";
import {DeploySCWallet} from "../utils/DeploySCW.sol";
import {DeployMockMarketPlace} from "../utils/DeployMockMarketPlace.sol";
import {MockMarketplace} from "../../contracts/mocks/MockMarketPlace.sol";
import {DeployFakeEOA} from "../utils/DeployFakeEOA.sol";

contract AllowlistERC721TransferApprovals is Test {
    OperatorAllowlistUpgradeable public allowlist;
    ImmutableERC721 public immutableERC721;
    DeploySCWallet public deploySCWScript;
    DeployMockMarketPlace public deployMockMarketPlaceScript;
    DeployFakeEOA public deployFakeEOAScript;
    MockMarketplace public mockMarketPlace;

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

        immutableERC721 = new ImmutableERC721(
            admin,
            "test",
            "USDC",
            "test-base-uri",
            "test-contract-uri",
            address(allowlist),
            feeReceiver,
            0
        );

        nonAuthorizedWallet = address(0x2);

        deploySCWScript = new DeploySCWallet();

        deployMockMarketPlaceScript = new DeployMockMarketPlace();
        mockMarketPlace = deployMockMarketPlaceScript.run(address(immutableERC721));
        _giveMinterRole();
    }

    function testDeployment() public {
        assertEq(address(immutableERC721.operatorAllowlist()), proxyAddr);
    }

    function _addSCWAddressAllowListAndApprove(address _address) private {
        vm.startPrank(registrar);
        allowlist.addWalletToAllowlist(_address);
        immutableERC721.setApprovalForAll(_address, true);
        vm.stopPrank();
    }

    function _giveMinterRole() public {
        vm.prank(admin);
        immutableERC721.grantMinterRole(minter);
        bytes32 minterRole = immutableERC721.MINTER_ROLE();
        assertTrue(immutableERC721.hasRole(minterRole, minter));
    }

    function testShouldNotApproveNoneOALSCW() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, scwModuleAddr) = deploySCWScript.run(salt);

        vm.prank(minter);
        immutableERC721.safeMint(admin, 1);

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("ApproveTargetNotInAllowlist(address)", scwAddr));
        immutableERC721.setApprovalForAll(scwAddr, true);

        vm.expectRevert(abi.encodeWithSignature("ApproveTargetNotInAllowlist(address)", scwAddr));
        immutableERC721.approve(scwAddr, 1);
        vm.stopPrank();
    }

    function testShouldNotAllowApproveFromNoneOALContract() public {
        vm.startPrank(minter);
        immutableERC721.mint(address(mockMarketPlace), 1);
        vm.expectRevert(abi.encodeWithSignature("ApproverNotInAllowlist(address)", address(mockMarketPlace)));
        mockMarketPlace.executeApproveForAll(minter, true);
        vm.stopPrank();
    }

    function testShouldApproveEOA() public {
        vm.startPrank(minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.safeMint(minter, 2);

        immutableERC721.approve(admin, 1);
        assertEq(immutableERC721.getApproved(1), admin);
        immutableERC721.setApprovalForAll(admin, true);
        assertTrue(immutableERC721.isApprovedForAll(minter, admin));
        vm.stopPrank();
    }

    function testShouldApproveWalletInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, ) = deploySCWScript.run(salt);

        vm.prank(registrar);
        allowlist.addWalletToAllowlist(scwAddr);

        vm.startPrank(minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.safeMint(minter, 2);
        immutableERC721.approve(scwAddr, 1);
        assertEq(immutableERC721.getApproved(1), scwAddr);
        immutableERC721.setApprovalForAll(scwAddr, true);
        assertTrue(immutableERC721.isApprovedForAll(minter, scwAddr));
        vm.stopPrank();
    }

    function testShouldApproveAddrInOAL() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(mockMarketPlace);

        vm.prank(registrar);
        allowlist.addAddressesToAllowlist(addressTargets);

        vm.startPrank(minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.safeMint(minter, 2);
        immutableERC721.approve(address(mockMarketPlace), 1);
        assertEq(immutableERC721.getApproved(1), address(mockMarketPlace));
        immutableERC721.setApprovalForAll(address(mockMarketPlace), true);
        assertTrue(immutableERC721.isApprovedForAll(minter, address(mockMarketPlace)));
        vm.stopPrank();
    }

    function testTransferBetweenEOAs() public {
        vm.startPrank(minter, minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.approve(admin, 1);
        immutableERC721.transferFrom(minter, admin, 1);
        assertEq(immutableERC721.ownerOf(1), admin);
        vm.stopPrank();
    }

    function testBlockTransferForNoneOALWallet() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, ) = deploySCWScript.run(salt);

        vm.startPrank(minter, minter);
        immutableERC721.safeMint(minter, 1);
        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", scwAddr));
        immutableERC721.transferFrom(minter, scwAddr, 1);
        vm.stopPrank();
    }

    function testBlockTransferForNoneOALAddr() public {
        vm.startPrank(minter, minter);
        immutableERC721.safeMint(minter, 1);
        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", address(mockMarketPlace)));
        immutableERC721.transferFrom(minter, address(mockMarketPlace), 1);
        vm.stopPrank();
    }

    function testTransferToAddrInOAL() public {
        address[] memory addressTargets = new address[](1);
        addressTargets[0] = address(mockMarketPlace);

        vm.prank(registrar);
        allowlist.addAddressesToAllowlist(addressTargets);

        vm.startPrank(minter, minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.transferFrom(minter, address(mockMarketPlace), 1);
        assertEq(immutableERC721.ownerOf(1), address(mockMarketPlace));
        vm.stopPrank();
    }

    function testTransferToWalletInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (scwAddr, ) = deploySCWScript.run(salt);

        vm.prank(registrar);
        allowlist.addWalletToAllowlist(scwAddr);

        vm.startPrank(minter, minter);
        immutableERC721.safeMint(minter, 1);
        immutableERC721.transferFrom(minter, scwAddr, 1);
        assertEq(immutableERC721.ownerOf(1), scwAddr);
        vm.stopPrank();
    }

    function testTransferBetweenSCWInOAL() public {
        bytes32 salt = keccak256(abi.encodePacked("0x1234"));
        (address scwAddr1, ) = deploySCWScript.run(salt);
        MockWallet scw1 = MockWallet(scwAddr1);

        bytes32 salt2 = keccak256(abi.encodePacked("0x5678"));
        (address scwAddr2, ) = deploySCWScript.run(salt2);

        vm.startPrank(registrar);
        allowlist.addWalletToAllowlist(scwAddr1);
        allowlist.addWalletToAllowlist(scwAddr2);

        vm.startPrank(minter, minter);
        immutableERC721.safeMint(scwAddr1, 1);
        scw1.transferNFT(address(immutableERC721), scwAddr1, scwAddr2, 1);
        assertEq(immutableERC721.ownerOf(1), scwAddr2);
        vm.stopPrank();
    }



}