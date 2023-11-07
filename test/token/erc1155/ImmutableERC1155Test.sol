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
            "test",
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
