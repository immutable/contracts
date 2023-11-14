// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {ImmutableERC1155} from "../../../contracts/token/erc1155/preset/draft-ImmutableERC1155.sol";
import {IImmutableERC1155Errors} from "../../../contracts/errors/Errors.sol";
import {OperatorAllowlist} from "../../../contracts/allowlist/OperatorAllowlist.sol";
import {Sign} from "../../utils/Sign.sol";

contract ImmutableERC1155Test is Test {
    ImmutableERC1155 public immutableERC1155;
    Sign public sign;
    OperatorAllowlist public operatorAllowlist;

    uint256 deployerPrivateKey = 1;
    uint256 ownerPrivateKey = 2;
    uint256 spenderPrivateKey = 3;
    uint256 anotherPrivateKey = 4;
    uint256 feeReceiverKey = 5;

    address deployer = vm.addr(deployerPrivateKey);
    address owner = vm.addr(ownerPrivateKey);
    address spender = vm.addr(spenderPrivateKey);
    address feeReceiver = vm.addr(feeReceiverKey);

    function setUp() public {
        operatorAllowlist = new OperatorAllowlist(
            owner
        );
        immutableERC1155 = new ImmutableERC1155(
            owner,
            "test",
            "test-base-uri",
            "test-contract-uri",
            address(operatorAllowlist),
            feeReceiver,
            0
        );
        sign = new Sign(immutableERC1155.DOMAIN_SEPARATOR());
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

    /*
    * Contract deployment
    */
    function test_DeploymentShouldSetAdminRoleToOwner() public {
        bytes32 adminRole = immutableERC1155.DEFAULT_ADMIN_ROLE();
        assertTrue(immutableERC1155.hasRole(adminRole, owner));
    }

    function test_DeploymentShouldSetContractURI() public {
        assertEq(immutableERC1155.contractURI(), "test-contract-uri");
    }

    function test_DeploymentShouldSetBaseURI() public {
        assertEq(immutableERC1155.baseURI(), "test-base-uri");
    }

    /*
    * Metadata
    */
    function test_AdminRoleCanSetContractURI() public {
        vm.prank(owner);
        immutableERC1155.setContractURI("new-contract-uri");
        assertEq(immutableERC1155.contractURI(), "new-contract-uri");
    }

    function test_RevertIfNonAdminAttemptsToSetContractURI() public {
        vm.prank(vm.addr(anotherPrivateKey));
        vm.expectRevert("AccessControl: account 0x1eff47bc3a10a45d4b230b5d10e37751fe6aa718 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        immutableERC1155.setContractURI("new-contract-uri");
    }

    function test_AdminRoleCanSetBaseURI() public {
        vm.prank(owner);
        immutableERC1155.setBaseURI("new-base-uri");
        assertEq(immutableERC1155.baseURI(), "new-base-uri");
    }

    function test_RevertIfNonAdminAttemptsToSetBaseURI() public {
        vm.prank(vm.addr(anotherPrivateKey));
        vm.expectRevert("AccessControl: account 0x1eff47bc3a10a45d4b230b5d10e37751fe6aa718 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        immutableERC1155.setBaseURI("new-base-uri");
    }

    /*
    * Permits
    */
    function test_PermitSuccess() public {
        bytes memory sig = _sign(ownerPrivateKey, owner, spender, true, 0, 1 days);

        immutableERC1155.permit(owner, spender, true, 1 days, sig);

        assertEq(immutableERC1155.isApprovedForAll(owner, spender), true);
        assertEq(immutableERC1155.nonces(owner), 1);
    }

    function test_PermitRevertsWhenInvalidNonce() public {
        bytes memory sig = _sign(anotherPrivateKey, owner, spender, true, 5, 1 days);

        vm.expectRevert(IImmutableERC1155Errors.InvalidSignature.selector);

        immutableERC1155.permit(owner, spender, true, 1 days, sig);
    }

    function test_PermitRevertsWhenInvalidSigner() public {
        bytes memory sig = _sign(anotherPrivateKey, owner, spender, true, 0, 1 days);

        vm.expectRevert(IImmutableERC1155Errors.InvalidSignature.selector);

        immutableERC1155.permit(owner, spender, true, 1 days, sig);
    }

    function test_PermitRevertsWhenDeadlineExceeded() public {
        bytes memory sig = _sign(ownerPrivateKey, owner, spender, true, 0, 1 days);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(IImmutableERC1155Errors.PermitExpired.selector);

        immutableERC1155.permit(owner, spender, true, 1 days, sig);
    }
}
