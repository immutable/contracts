// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";
import {GuardedMulticaller2} from "../../contracts/multicall/GuardedMulticaller2.sol";
import {MockFunctions} from "../../contracts/mocks/MockFunctions.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SigUtils} from "./SigUtils.t.sol";

contract GuardedMulticaller2Test is Test {
    GuardedMulticaller2 gmc;
    SigUtils sigUtils;
    MockFunctions target;
    MockFunctions target1;

    address defaultAdmin = makeAddr("defaultAdmin");
    address signer;
    uint256 signerPk;

    event Multicalled(
        address indexed _multicallSigner,
        bytes32 indexed _reference,
        GuardedMulticaller2.Call[] _calls,
        uint256 _deadline
    );

    function setUp() public {
        target = new MockFunctions();
        target1 = new MockFunctions();
        (signer, signerPk) = makeAddrAndKey("signer");

        gmc = new GuardedMulticaller2(defaultAdmin, "name", "1");
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
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](3);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );
        calls[1] = GuardedMulticaller2.Call(address(target), "succeed()", "");
        calls[2] = GuardedMulticaller2.Call(
            address(target1),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectCall(address(target), abi.encodeCall(target.succeedWithUint256, (uint256(42))));
        vm.expectCall(address(target), abi.encodeCall(target.succeed, ()));
        vm.expectCall(address(target1), abi.encodeCall(target1.succeedWithUint256, (uint256(42))));
        vm.expectEmit(true, true, false, true, address(gmc));
        emit Multicalled(signer, ref, calls, deadline);

        gmc.execute(signer, ref, calls, deadline, signature);

        assertTrue(gmc.hasBeenExecuted(ref));
    }

    function test_RevertWhen_ExecuteExpired() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp - 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.Expired.selector, deadline));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteInvalidReference() public {
        bytes32 ref = "";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.InvalidReference.selector, ref));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteReusedReference() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        gmc.execute(signer, ref, calls, deadline, signature);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.ReusedReference.selector, ref));
        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteEmptyCallArray() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](0);

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(GuardedMulticaller2.EmptyCallArray.selector);

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteNonContractAddress() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(address(0), "succeedWithUint256(uint256)", abi.encodePacked(uint256(42)));

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.NonContractAddress.selector, calls[0]));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteUnauthorizedSigner() public {
        (address fakeSigner, uint256 fakeSignerPk) = makeAddrAndKey("fakeSigner");
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.UnauthorizedSigner.selector, fakeSigner));

        gmc.execute(fakeSigner, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteUnauthorizedSignature() public {
        (, uint256 fakeSignerPk) = makeAddrAndKey("fakeSigner");
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.UnauthorizedSignature.selector, signature));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteFailedCall() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(address(target), "revertWithNoReason()", "");

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.FailedCall.selector, calls[0], ""));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteRevokeMinterRole() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        gmc.execute(signer, ref, calls, deadline, signature);

        vm.startPrank(defaultAdmin);
        gmc.revokeMulticallSignerRole(signer);
        vm.stopPrank();

        bytes32 ref1 = keccak256("ref1");
        bytes32 digest1 = sigUtils.hashTypedData(ref1, calls, deadline);
        (v, r, s) = vm.sign(signerPk, digest1);
        bytes memory signature1 = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.UnauthorizedSigner.selector, signer));
        gmc.execute(signer, ref1, calls, deadline, signature1);
        bool executed = gmc.hasBeenExecuted(ref1);
        assertFalse(executed);
    }

    function test_RevertWhen_ExecuteBubbleUpRevertReason() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(address(target), "revertWithData(uint256)", abi.encodePacked(uint256(42)));

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(MockFunctions.RevertWithData.selector, uint256(42)));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ExecuteInvalidFunctionSignature() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](1);
        calls[0] = GuardedMulticaller2.Call(address(target), "", abi.encodePacked(uint256(42)));

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller2.InvalidFunctionSignature.selector, calls[0]));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    // TODO: test reentrancy
    function test_RevertWhen_ExecuteReentrant() public {}
}
