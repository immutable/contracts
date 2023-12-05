// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {ImmutableERC1155} from "../../../contracts/token/erc1155/preset/draft-ImmutableERC1155.sol";
import {IImmutableERC1155Errors} from "../../../contracts/errors/Errors.sol";
import {OperatorAllowlistEnforcementErrors} from "../../../contracts/errors/Errors.sol";
import {OperatorAllowlist} from "../../../contracts/allowlist/OperatorAllowlist.sol";
import {Sign} from "../../utils/Sign.sol";
import {MockWallet} from "../../../contracts/mocks/MockWallet.sol";
import {MockWalletFactory} from "../../../contracts/mocks/MockWalletFactory.Sol";

contract ImmutableERC1155Test is Test {
    ImmutableERC1155 public immutableERC1155;
    Sign public sign;
    OperatorAllowlist public operatorAllowlist;
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

        operatorAddrs.push(minter);
        vm.startPrank(owner);
        bytes32 regiRole = operatorAllowlist.REGISTRAR_ROLE();
        operatorAllowlist.grantRegistrarRole(owner);
        assertTrue(operatorAllowlist.hasRole(regiRole, owner));
        vm.stopPrank();

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
        operatorAllowlist.addAddressToAllowlist(operatorAddrs);
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
    * Role
    */
    function test_giveMinterRole() public {
        vm.prank(owner);
        immutableERC1155.grantMinterRole(minter);
        bytes32 minterRole = immutableERC1155.MINTER_ROLE();
        assertTrue(immutableERC1155.hasRole(minterRole, minter));
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

    function test_DeploymentAllowlistShouldGiveAdminToOwner() public {
        bytes32 adminRole = operatorAllowlist.DEFAULT_ADMIN_ROLE();
        assertTrue(operatorAllowlist.hasRole(adminRole, owner));
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

    /*
    * Mints
    */
    function test_MinterRoleCanMint() public {
        vm.prank(minter);
        immutableERC1155.safeMint(minter, 1, 1, "");
        assertEq(immutableERC1155.balanceOf(minter, 1), 1);
    }

    function test_MinterRoleCanBatchMint() public {
        vm.prank(minter);
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;

        amounts[0] = 10;
        amounts[1] = 5;
        amounts[2] = 9;
        immutableERC1155.safeMintBatch(minter, ids, amounts, "");
        assertEq(immutableERC1155.balanceOf(minter, 1), 10);
        assertEq(immutableERC1155.balanceOf(minter, 2), 5);
        assertEq(immutableERC1155.balanceOf(minter, 3), 9);
    }

    /*
    * transfers
    */
    function test_ApprovedOperatorTransferFrom() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");

        _addAddrToAllowListAndApprove();

        vm.prank(minter);
        immutableERC1155.safeTransferFrom(owner, spender, 1, 1, "");
        assertEq(immutableERC1155.balanceOf(spender, 1), 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
    }

    function test_ApprovedOperatorBatchTransferFrom() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");
        immutableERC1155.safeMint(owner, 2, 1, "");
        vm.stopPrank();

        _addAddrToAllowListAndApprove();

        vm.prank(minter);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 1;
        ids[1] = 2;

        amounts[0] = 1;
        amounts[1] = 1;
        immutableERC1155.safeBatchTransferFrom(owner, spender, ids, amounts, "");
        assertEq(immutableERC1155.balanceOf(spender, 1), 1);
        assertEq(immutableERC1155.balanceOf(spender, 2), 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
        assertEq(immutableERC1155.balanceOf(owner, 2), 0);
    }

    function test_ApprovedSCWOperatorTransferFrom() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");

        _addSCWAddressAllowListAndApprove(scwAddress);

        vm.prank(scwOwner);
        scw.transfer1155(address(immutableERC1155), owner, spender, 1, 1);
        assertEq(immutableERC1155.balanceOf(spender, 1), 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
    }

    function test_ApprovedSCWOperatorTransferFromToApprovedReceiver() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");

        _addSCWAddressAllowListAndApprove(scwAddress);

        vm.prank(scwOwner);
        scw.transfer1155(address(immutableERC1155), owner, scwAddress, 1, 1);
        assertEq(immutableERC1155.balanceOf(scwAddress, 1), 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
    }

    function test_ApprovedSCWOperatorTransferFromToUnApprovedReceiver() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");

        _addSCWAddressAllowListAndApprove(scwAddress);

        vm.expectRevert(abi.encodeWithSignature("TransferToNotInAllowlist(address)", anotherScwAddress));

        vm.prank(scwOwner);
        scw.transfer1155(address(immutableERC1155), owner, anotherScwAddress, 1, 1);
    }

    function test_ApprovedSCWOperatorBatchTransferFromToApprovedReceiver() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");
        immutableERC1155.safeMint(owner, 2, 1, "");
        vm.stopPrank();

        _addSCWAddressAllowListAndApprove(scwAddress);

        vm.prank(scwOwner);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 1;
        ids[1] = 2;

        amounts[0] = 1;
        amounts[1] = 1;
        scw.batchTransfer1155(address(immutableERC1155), owner, scwAddress, ids, amounts);
        assertEq(immutableERC1155.balanceOf(scwAddress, 1), 1);
        assertEq(immutableERC1155.balanceOf(scwAddress, 2), 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
        assertEq(immutableERC1155.balanceOf(owner, 2), 0);
    }

    /*
    * Approve
    */
    function test_UnapprovedSCWOperatorTransferFrom() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");
        vm.expectRevert(abi.encodeWithSignature("ApproveTargetNotInAllowlist(address)", scwAddress));
        vm.startPrank(owner);
        immutableERC1155.setApprovalForAll(scwAddress, true);
        vm.stopPrank();
    }

   /*
   * Burn
   */
   function test_Burn() public {
        vm.prank(minter);
        immutableERC1155.safeMint(owner, 1, 1, "");
        vm.prank(owner);
        immutableERC1155.burn(owner, 1, 1);
        assertEq(immutableERC1155.balanceOf(owner, 1), 0);
    }

    function test_BatchBurn() public {
        vm.startPrank(minter);
        immutableERC1155.safeMint(owner, 1, 10, "");
        immutableERC1155.safeMint(owner, 2, 10, "");
        assertEq(immutableERC1155.totalSupply(1), 10);
        vm.stopPrank();

        vm.prank(owner);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 5;
        amounts[1] = 3;
        immutableERC1155.burnBatch(owner, ids, amounts);
        assertEq(immutableERC1155.balanceOf(owner, 1), 5);
        assertEq(immutableERC1155.balanceOf(owner, 2), 7);
        assertEq(immutableERC1155.totalSupply(1), 5);
    }
}
