// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {GuardedMulticallerV2} from "../../contracts/multicall/GuardedMulticallerV2.sol";
import {MockFunctions} from "../../contracts/mocks/MockFunctions.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SigUtils} from "./SigUtils.t.sol";

contract GuardedMulticallerV2Test is Test {
    GuardedMulticallerV2 gmc;
    SigUtils sigUtils;
    MockFunctions target;

    address defaultAdmin = makeAddr("defaultAdmin");
    address signer;
    uint256 signerPk;

    function setUp() public {
        target = new MockFunctions();
        (signer, signerPk) = makeAddrAndKey("signer");

        gmc = new GuardedMulticallerV2(defaultAdmin, "name", "1");
        vm.prank(defaultAdmin);
        gmc.grantMulticallSignerRole(signer);

        sigUtils = new SigUtils("name", "1", address(gmc));
    }

    function test_Roles() public {
        assertTrue(gmc.hasRole(gmc.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(gmc.hasRole(gmc.MULTICALL_SIGNER_ROLE(), signer));
    }

    function test_Execute() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(address(target), "succeed()", "");
        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        gmc.execute(signer, ref, calls, deadline, signature);
        assertTrue(gmc.hasBeenExecuted(ref));
    }

    function test_RevertWhen_UnauthorizedSigner() public {
        (address fakeSigner, uint256 fakeSignerPk) = makeAddrAndKey("fakeSigner");
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(address(target), "revertWithNoReason()", "");
        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.UnauthorizedSigner.selector, fakeSigner));
        gmc.execute(fakeSigner, ref, calls, deadline, signature);
    }

    function test_RevertWhen_CallFailed() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(address(target), "revertWithNoReason()", "");
        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.FailedCall.selector, calls[0]));
        gmc.execute(signer, ref, calls, deadline, signature);
    }
}
