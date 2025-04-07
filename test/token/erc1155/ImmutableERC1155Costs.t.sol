// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";
import {ImmutableERC1155} from "../../../contracts/token/erc1155/preset/ImmutableERC1155.sol";
import {IImmutableERC1155Errors} from "../../../contracts/errors/Errors.sol";
import {OperatorAllowlistEnforcementErrors} from "../../../contracts/errors/Errors.sol";
import {OperatorAllowlistUpgradeable} from "../../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {Sign} from "../../utils/Sign.sol";
import {DeployOperatorAllowlist} from "../../utils/DeployAllowlistProxy.sol";
import {MockWallet} from "../../../contracts/mocks/MockWallet.sol";
import {MockWalletFactory} from "../../../contracts/mocks/MockWalletFactory.sol";

contract ImmutableERC1155Costs is Test {
    ImmutableERC1155 public immutableERC1155;
    Sign public sign;
    OperatorAllowlistUpgradeable public operatorAllowlist;
    MockWalletFactory public scmf;
    MockWallet public mockWalletModule;
    MockWallet public scw;
    MockWallet public anotherScw;
    address[] private operatorAddrs;

    uint256 deployerPrivateKey = 1;
    uint256 ownerPrivateKey = 2;
    uint256 spenderPrivateKey = 3;
    uint256 anotherPrivateKey = 4;
    uint256 feeReceiverKey = 5;
    uint256 minterPrivateKey = 6;
    uint256 scwPrivateKey = 7;

    address deployer = vm.addr(deployerPrivateKey);
    address owner = vm.addr(ownerPrivateKey);
    address spender = vm.addr(spenderPrivateKey);
    address feeReceiver = vm.addr(feeReceiverKey);
    address minter = vm.addr(minterPrivateKey);
    address scwOwner = vm.addr(scwPrivateKey);

    bytes32 salt = keccak256(abi.encodePacked("0x1234"));
    bytes32 anotherSalt = keccak256(abi.encodePacked("0x12345"));

    address public scwAddress;
    address public anotherScwAddress;
    address public proxyAddr;

    function setUp() public {
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        proxyAddr = deployScript.run(owner, owner, owner);
        operatorAllowlist = OperatorAllowlistUpgradeable(proxyAddr);

        immutableERC1155 = new ImmutableERC1155(
            owner, "test", "test-base-uri", "test-contract-uri", address(operatorAllowlist), feeReceiver, 0
        );

        operatorAddrs.push(minter);
        assertTrue(operatorAllowlist.hasRole(operatorAllowlist.REGISTRAR_ROLE(), owner));

        sign = new Sign(immutableERC1155.DOMAIN_SEPARATOR());
        vm.prank(owner);
        immutableERC1155.grantMinterRole(minter);

        scmf = new MockWalletFactory();

        vm.prank(scwOwner);
        mockWalletModule = new MockWallet();
        scmf.deploy(address(mockWalletModule), salt);
        scwAddress = scmf.getAddress(address(mockWalletModule), salt);
        scw = MockWallet(scwAddress);

        mockWalletModule = new MockWallet();
        scmf.deploy(address(mockWalletModule), anotherSalt);
        anotherScwAddress = scmf.getAddress(address(mockWalletModule), anotherSalt);
        anotherScw = MockWallet(anotherScwAddress);

        // vm.startPrank(minter);
        // immutableERC1155.safeMint(owner, 1, 1, "");
        // immutableERC1155.safeMint(minter, 1, 1, "");
        // immutableERC1155.safeMint(spender, 1, 1, "");
        // immutableERC1155.safeMint(feeReceiver, 1, 1, "");
        // immutableERC1155.safeMint(deployer, 1, 1, "");
    }

    function _sign(
        uint256 privateKey,
        address _owner,
        address _spender,
        bool _approved,
        uint256 _nonce,
        uint256 _deadline
    ) private view returns (bytes memory sig) {
        bytes32 digest = sign.buildPermitDigest(_owner, _spender, _approved, _nonce, _deadline);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        sig = abi.encodePacked(r, s, v);
    }

    function _addAddrToAllowListAndApprove() private {
        vm.startPrank(owner);
        operatorAllowlist.addAddressesToAllowlist(operatorAddrs);
        immutableERC1155.setApprovalForAll(minter, true);
        vm.stopPrank();
    }

    function _addSCWAddressAllowListAndApprove(address _address) private {
        vm.startPrank(owner);
        operatorAllowlist.addWalletToAllowlist(_address);
        immutableERC1155.setApprovalForAll(_address, true);
        vm.stopPrank();
    }
    /*
    * Mints
    */

    function test_Mint1To5() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(minter, 1, 1, "");
        // immutableERC1155.safeMint(owner, 1, 1, "");
        // immutableERC1155.safeMint(spender, 1, 1, "");
        // immutableERC1155.safeMint(feeReceiver, 1, 1, "");
        // immutableERC1155.safeMint(deployer, 1, 1, "");
    }

    function test_Mint5To5() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(minter, 1, 5, "");
        // immutableERC1155.safeMint(owner, 1, 5, "");
        // immutableERC1155.safeMint(spender, 1, 5, "");
        // immutableERC1155.safeMint(feeReceiver, 1, 5, "");
        // immutableERC1155.safeMint(deployer, 1, 5, "");
    }

    function test_Mint10To5() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(minter, 1, 10, "");
        // immutableERC1155.safeMint(owner, 1, 10, "");
        // immutableERC1155.safeMint(spender, 1, 10, "");
        // immutableERC1155.safeMint(feeReceiver, 1, 10, "");
        // immutableERC1155.safeMint(deployer, 1, 10, "");
    }

    function test_Mint100To1() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(minter, 1, 100, "");
    }
}
