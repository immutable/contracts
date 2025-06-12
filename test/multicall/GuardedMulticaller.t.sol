// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {GuardedMulticaller} from "../../contracts/multicall/GuardedMulticaller.sol";
import {MockFunctions} from "./MockFunctions.sol";
import {SigUtils} from "./SigUtils.t.sol";

contract GuardedMulticallerTest is Test {
    
    GuardedMulticaller public gmc;
    MockFunctions public mock;
    SigUtils public sigUtils;
    
    address public deployer;
    address public signer;
    uint256 public signerPk;
    address public user;
    uint256 public userPk;

    string public constant MULTICALLER_NAME = "Multicaller";
    string public constant MULTICALLER_VERSION = "v1";
    
    bytes32 public ref;
    uint256 public deadline;
    
    function setUp() public {
        deployer = makeAddr("deployer");
        (signer, signerPk) = makeAddrAndKey("signer");
        (user, userPk) = makeAddrAndKey("user");
        
        vm.prank(deployer);
        gmc = new GuardedMulticaller(deployer, MULTICALLER_NAME, MULTICALLER_VERSION);
        vm.prank(deployer);
        gmc.grantMulticallSignerRole(signer);
        
        sigUtils = new SigUtils(MULTICALLER_NAME, MULTICALLER_VERSION, address(gmc));


        vm.prank(deployer);
        mock = new MockFunctions();

        GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](2);
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.succeed.selector,
            permitted: true
        });
        functionPermits[1] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.revertWithNoReason.selector,
            permitted: true
        });
        vm.prank(deployer);
        gmc.setFunctionPermits(functionPermits);

        
        deadline = block.timestamp + 30 minutes;
        ref = keccak256(abi.encodePacked("test_ref"));
    }
    
    function test_SuccessfulExecution() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MockFunctions.succeed.selector);
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit GuardedMulticaller.Multicalled(signer, ref, targets, data, deadline);
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertWithCustomError() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("revertWithNoReason()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.FailedCall.selector, targets[0], data[0]));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfDeadlinePassed() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        

        uint256 expiredDeadline = block.timestamp;
        vm.warp(expiredDeadline + 30 minutes);
        bytes memory signature = signTypedData(signerPk, ref, targets, data, expiredDeadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.Expired.selector, expiredDeadline));
        gmc.execute(signer, ref, targets, data, expiredDeadline, signature);
    }
    
    function test_RevertIfReferenceReused() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        gmc.execute(signer, ref, targets, data, deadline, signature);
        
        vm.prank(user);
        vm.expectRevert(abi.encodePacked(GuardedMulticaller.ReusedReference.selector, ref));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfInvalidReference() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes32 invalidRef = bytes32(0);
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.InvalidReference.selector, invalidRef));
        gmc.execute(signer, invalidRef, targets, data, deadline, signature);
    }
    
    function test_RevertIfUnauthorizedSigner() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.UnauthorizedSigner.selector, user));
        // Note: execute called with user as signer. 
        gmc.execute(user, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfSignatureMismatch() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(userPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.UnauthorizedSignature.selector, signature));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfEmptyTargets() public {
        address[] memory targets = new address[](0);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.EmptyAddressArray.selector));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfTargetsDataMismatch() public {
        address[] memory targets = new address[](2);
        targets[0] = address(mock);
        targets[1] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
            GuardedMulticaller.AddressDataArrayLengthsMismatch.selector, 
            targets.length, data.length));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }

    function test_RevertIfFunctionNotPermitted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("notPermitted()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.UnauthorizedFunction.selector, targets[0], data[0]));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfFunctionDisallowed() public {
        GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](1);
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.succeed.selector,
            permitted: false
        });
        vm.prank(deployer);
        gmc.setFunctionPermits(functionPermits);
        
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.UnauthorizedFunction.selector, targets[0], data[0]));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_RevertIfInvalidSignature() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes32 maliciousRef = keccak256(abi.encodePacked("malicious_ref"));
        bytes memory signature = signTypedData(signerPk, maliciousRef, targets, data, deadline);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.UnauthorizedSignature.selector, signature));
        gmc.execute(signer, ref, targets, data, deadline, signature);
    }
    
    function test_EmitFunctionPermittedEvent() public {
        vm.startPrank(deployer);
        GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](1);
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.succeed.selector,
            permitted: true
        });
        vm.expectEmit(true, true, true, true);
        emit GuardedMulticaller.FunctionPermitted(
            address(mock),
            MockFunctions.succeed.selector,
            true
        );
        gmc.setFunctionPermits(functionPermits);
        
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.succeed.selector,
            permitted: false
        });
        vm.expectEmit(true, true, true, true);
        emit GuardedMulticaller.FunctionPermitted(
            address(mock),
            MockFunctions.succeed.selector,
            false
        );
        gmc.setFunctionPermits(functionPermits);
        
        vm.stopPrank();
    }

    function test_RevertIfEmptyFunctionPermits() public {
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.EmptyFunctionPermitArray.selector));
        gmc.setFunctionPermits(new GuardedMulticaller.FunctionPermit[](0));
    }

    function test_RevertIfAccessControlIssueWhileSettingFunctionPermits() public {
        GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](1);
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: address(mock),
            functionSelector: MockFunctions.succeed.selector,
            permitted: false
        });
        vm.prank(user);
        // Will be an access control error.
        vm.expectRevert();
        gmc.setFunctionPermits(functionPermits);
    }


    function test_RevertIfSetFunctionPermitsNonContract() public {
        GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](1);
        functionPermits[0] = GuardedMulticaller.FunctionPermit({
            target: deployer,
            functionSelector: MockFunctions.succeed.selector,
            permitted: true
        });
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(GuardedMulticaller.NonContractAddress.selector, deployer));
        gmc.setFunctionPermits(functionPermits);
    }
    
    function test_RevertIfGrantRevokeSignerRoleWithInvalidRole() public {
        vm.startPrank(user);
        
        vm.expectRevert();
        gmc.grantMulticallSignerRole(user);
        
        vm.expectRevert();
        gmc.revokeMulticallSignerRole(user);
        
        vm.stopPrank();
    }
    
    function test_HasBeenExecuted() public {
        address[] memory targets = new address[](1);
        targets[0] = address(mock);
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("succeed()");
        
        bytes memory signature = signTypedData(signerPk, ref, targets, data, deadline);
        
        vm.prank(user);
        gmc.execute(signer, ref, targets, data, deadline, signature);
        
        assertTrue(gmc.hasBeenExecuted(ref));
        
        bytes32 invalidRef = keccak256(abi.encodePacked("invalid_ref"));
        assertFalse(gmc.hasBeenExecuted(invalidRef));
    }

    function testIsFunctionPermitted() public {
        assertTrue(gmc.isFunctionPermitted(address(mock), MockFunctions.succeed.selector));
        assertTrue(gmc.isFunctionPermitted(address(mock), MockFunctions.revertWithNoReason.selector));
        assertFalse(gmc.isFunctionPermitted(address(mock), MockFunctions.notPermitted.selector));
    }

    function testHashBytesArray() public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("succeed()");
        data[1] = abi.encodeWithSignature("notSucceed()");
        assertEq(sigUtils.hashBytesArray(data), gmc.hashBytesArray(data));
    }

    function signTypedData(
        uint256 _signerPk,
        bytes32 _reference,
        address[] memory _targets,
        bytes[] memory _data,
        uint256 _deadline
    ) public view returns (bytes memory) {
        bytes32 digest = sigUtils.hashTypedData(_reference, _targets, _data, _deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPk, digest);
        return abi.encodePacked(r, s, v);
    }

} 