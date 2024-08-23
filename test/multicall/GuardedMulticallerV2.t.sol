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
    MockFunctions target1;

    address defaultAdmin = makeAddr("defaultAdmin");
    address signer;
    uint256 signerPk;

    event Multicalled(
        address indexed _multicallSigner,
        bytes32 indexed _reference,
        GuardedMulticallerV2.Call[] _calls,
        uint256 _deadline
    );

    function setUp() public {
        target = new MockFunctions();
        target1 = new MockFunctions();
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
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](3);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );
        calls[1] = GuardedMulticallerV2.Call(address(target), "succeed()", "");
        calls[2] = GuardedMulticallerV2.Call(
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

    function test_RevertWhen_Expired() public {
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp - 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.Expired.selector, deadline));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_InvalidReference() public {
        bytes32 ref = "";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.InvalidReference.selector, ref));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_ReusedReference() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        gmc.execute(signer, ref, calls, deadline, signature);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.ReusedReference.selector, ref));
        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_EmptyCallArray() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](0);

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(GuardedMulticallerV2.EmptyCallArray.selector);

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_NonContractAddress() public {
        bytes32 ref = "ref";
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(address(0), "succeedWithUint256(uint256)", abi.encodePacked(uint256(42)));

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.NonContractAddress.selector, calls[0]));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_UnauthorizedSigner() public {
        (address fakeSigner, uint256 fakeSignerPk) = makeAddrAndKey("fakeSigner");
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.UnauthorizedSigner.selector, fakeSigner));

        gmc.execute(fakeSigner, ref, calls, deadline, signature);
    }

    function test_RevertWhen_UnauthorizedSignature() public {
        (, uint256 fakeSignerPk) = makeAddrAndKey("fakeSigner");
        bytes32 ref = keccak256("ref");
        uint256 deadline = block.timestamp + 1;
        GuardedMulticallerV2.Call[] memory calls = new GuardedMulticallerV2.Call[](1);
        calls[0] = GuardedMulticallerV2.Call(
            address(target),
            "succeedWithUint256(uint256)",
            abi.encodePacked(uint256(42))
        );

        bytes32 digest = sigUtils.hashTypedData(ref, calls, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(GuardedMulticallerV2.UnauthorizedSignature.selector, signature));

        gmc.execute(signer, ref, calls, deadline, signature);
    }

    function test_RevertWhen_FailedCall() public {
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
