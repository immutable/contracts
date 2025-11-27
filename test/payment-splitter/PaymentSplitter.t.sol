// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";
import {PaymentSplitter} from "../../contracts/payment-splitter/PaymentSplitter.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract PaymentSplitterTest is Test {
    event PaymentReleased(address to, uint256 amount);

    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    event PaymentReceived(address from, uint256 amount);

    PaymentSplitter public paymentSplitter;
    MockERC20 public mockToken1;
    MockERC20 public mockToken2;

    address payee1 = makeAddr("payee1");
    address payee2 = makeAddr("payee2");
    address payee3 = makeAddr("payee3");
    address payee4 = makeAddr("payee4");
    address defaultAdmin = makeAddr("defaultAdmin");
    address registrarAdmin = makeAddr("registrarAdmin");
    address fundsAdmin = makeAddr("fundsAdmin");

    address payable[] payees = new address payable[](2);
    IERC20[] erc20s = new IERC20[](2);
    uint256[] shares = new uint256[](2);

    function setUp() public {
        mockToken1 = new MockERC20("MockToken1", "MT1");
        mockToken2 = new MockERC20("MockToken2", "MT2");
        erc20s[0] = mockToken1;
        erc20s[1] = mockToken2;

        shares[0] = 1;
        shares[1] = 4;

        payees[0] = payable(payee1);
        payees[1] = payable(payee2);

        vm.prank(defaultAdmin);
        paymentSplitter = new PaymentSplitter(defaultAdmin, registrarAdmin, fundsAdmin);

        vm.prank(registrarAdmin);
        paymentSplitter.addToAllowlist(erc20s);

        vm.prank(defaultAdmin);
        paymentSplitter.overridePayees(payees, shares);
    }

    function testDeployRoles() public view {
        assertTrue(paymentSplitter.hasRole(paymentSplitter.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(paymentSplitter.hasRole(paymentSplitter.TOKEN_REGISTRAR_ROLE(), registrarAdmin));
        assertTrue(paymentSplitter.hasRole(paymentSplitter.RELEASE_FUNDS_ROLE(), fundsAdmin));
    }

    function testTokensAdded() public view {
        assertEq(address(paymentSplitter.erc20Allowlist()[1]), address(erc20s[1]));
        assertEq(address(paymentSplitter.erc20Allowlist()[0]), address(erc20s[0]));
    }

    function testPayeeAdded() public view {
        assertEq(paymentSplitter.payee(0), payees[0]);
        assertEq(paymentSplitter.payee(1), payees[1]);
    }

    function testSharesAdded() public view {
        assertEq(paymentSplitter.shares(payees[0]), shares[0]);
        assertEq(paymentSplitter.shares(payees[1]), shares[1]);
    }

    function testInvalidPermissions() public {
        vm.prank(defaultAdmin);
        vm.expectRevert(
            "AccessControl: account 0x6fcb7bf6c32f0cd3bbc5fde0a55a80d3af6d0050 is missing role 0x544f4b454e5f5245474953545241525f524f4c45000000000000000000000000"
        );
        paymentSplitter.addToAllowlist(erc20s);

        vm.startPrank(registrarAdmin);
        vm.expectRevert(
            "AccessControl: account 0xa4985bf934d639cba655d34733ebf617e7f82429 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        paymentSplitter.overridePayees(payees, shares);
        vm.expectRevert(
            "AccessControl: account 0xa4985bf934d639cba655d34733ebf617e7f82429 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        paymentSplitter.revokeReleaseFundsRole(fundsAdmin);

        vm.expectRevert(
            "AccessControl: account 0xa4985bf934d639cba655d34733ebf617e7f82429 is missing role 0x52454c454153455f46554e44535f524f4c450000000000000000000000000000"
        );
        paymentSplitter.releaseAll();
        vm.stopPrank();
    }

    function testGrantReleaseFundsRole() public {
        vm.prank(defaultAdmin);
        address newfundAdmin = makeAddr("newfundAdmin");
        paymentSplitter.grantReleaseFundsRole(newfundAdmin);
        assertTrue(paymentSplitter.hasRole(paymentSplitter.RELEASE_FUNDS_ROLE(), newfundAdmin));
    }

    function testReleaseNativeTokenFundsSimple() public {
        assertEq(payee1.balance, 0);
        assertEq(payee2.balance, 0);

        vm.deal(address(paymentSplitter), 100);

        vm.startPrank(fundsAdmin);
        paymentSplitter.releaseAll();

        assertEq(payee1.balance, 20);
        assertEq(payee2.balance, 80);
        assertEq(address(paymentSplitter).balance, 0);

        vm.deal(address(paymentSplitter), 10);
        paymentSplitter.releaseAll();

        assertEq(payee1.balance, 22);
        assertEq(payee2.balance, 88);
        vm.stopPrank();
    }

    function testReleaseNativeFundsOverridePayees() public {
        assertEq(payee1.balance, 0);
        assertEq(payee2.balance, 0);

        vm.deal(address(paymentSplitter), 100);

        vm.prank(fundsAdmin);
        vm.expectEmit(true, true, false, false, address(paymentSplitter));
        emit PaymentReleased(payee1, 20);
        vm.expectEmit(true, true, false, false, address(paymentSplitter));
        emit PaymentReleased(payee2, 80);
        paymentSplitter.releaseAll();

        assertEq(payee1.balance, 20);
        assertEq(payee2.balance, 80);
        assertEq(address(paymentSplitter).balance, 0);

        address payable[] memory newPayees = new address payable[](2);
        uint256[] memory newShares = new uint256[](2);
        newPayees[0] = payable(payee3);
        newPayees[1] = payable(payee4);
        newShares[0] = 1;
        newShares[1] = 1;

        vm.prank(defaultAdmin);
        paymentSplitter.overridePayees(newPayees, newShares);

        vm.deal(address(paymentSplitter), 10);

        vm.prank(fundsAdmin);
        paymentSplitter.releaseAll();

        assertEq(payee1.balance, 20);
        assertEq(payee2.balance, 80);
        assertEq(payee3.balance, 5);
        assertEq(payee4.balance, 5);
    }

    function testReleaseERC20sSimple() public {
        assertEq(mockToken1.balanceOf(payee1), 0);
        assertEq(mockToken1.balanceOf(payee2), 0);
        assertEq(mockToken2.balanceOf(payee1), 0);
        assertEq(mockToken2.balanceOf(payee2), 0);

        mockToken1.mint(address(paymentSplitter), 100);
        mockToken2.mint(address(paymentSplitter), 100);

        vm.prank(fundsAdmin);
        vm.expectEmit(true, true, true, false, address(paymentSplitter));
        emit ERC20PaymentReleased(mockToken1, payee1, 20);
        vm.expectEmit(true, true, true, false, address(paymentSplitter));
        emit ERC20PaymentReleased(mockToken1, payee2, 80);
        paymentSplitter.releaseAll();

        assertEq(mockToken1.balanceOf(payee1), 20);
        assertEq(mockToken1.balanceOf(payee2), 80);
        assertEq(mockToken2.balanceOf(payee1), 20);
        assertEq(mockToken2.balanceOf(payee2), 80);

        assertEq(mockToken1.balanceOf(address(paymentSplitter)), 0);
        assertEq(mockToken2.balanceOf(address(paymentSplitter)), 0);

        mockToken1.mint(address(paymentSplitter), 10);
        mockToken2.mint(address(paymentSplitter), 10);

        vm.prank(fundsAdmin);
        paymentSplitter.releaseAll();

        assertEq(mockToken1.balanceOf(payee1), 22);
        assertEq(mockToken1.balanceOf(payee2), 88);
        assertEq(mockToken2.balanceOf(payee1), 22);
        assertEq(mockToken2.balanceOf(payee2), 88);
    }

    function testReleaseERC20sOverridePayees() public {
        assertEq(mockToken1.balanceOf(payee1), 0);
        assertEq(mockToken1.balanceOf(payee2), 0);
        assertEq(mockToken2.balanceOf(payee1), 0);
        assertEq(mockToken2.balanceOf(payee2), 0);

        mockToken1.mint(address(paymentSplitter), 100);
        mockToken2.mint(address(paymentSplitter), 100);

        vm.prank(fundsAdmin);
        paymentSplitter.releaseAll();

        assertEq(mockToken1.balanceOf(payee1), 20);
        assertEq(mockToken1.balanceOf(payee2), 80);
        assertEq(mockToken2.balanceOf(payee1), 20);
        assertEq(mockToken2.balanceOf(payee2), 80);

        assertEq(mockToken1.balanceOf(address(paymentSplitter)), 0);
        assertEq(mockToken2.balanceOf(address(paymentSplitter)), 0);

        mockToken1.mint(address(paymentSplitter), 10);
        mockToken2.mint(address(paymentSplitter), 10);

        address payable[] memory newPayees = new address payable[](2);
        uint256[] memory newShares = new uint256[](2);
        newPayees[0] = payable(payee3);
        newPayees[1] = payable(payee4);
        newShares[0] = 1;
        newShares[1] = 1;

        vm.prank(defaultAdmin);
        paymentSplitter.overridePayees(newPayees, newShares);

        vm.prank(fundsAdmin);
        paymentSplitter.releaseAll();

        assertEq(mockToken1.balanceOf(payee1), 20);
        assertEq(mockToken1.balanceOf(payee2), 80);
        assertEq(mockToken2.balanceOf(payee1), 20);
        assertEq(mockToken2.balanceOf(payee2), 80);

        assertEq(mockToken1.balanceOf(payee3), 5);
        assertEq(mockToken1.balanceOf(payee4), 5);
        assertEq(mockToken2.balanceOf(payee3), 5);
        assertEq(mockToken2.balanceOf(payee4), 5);
    }

    function testCalculateReleasableAmount() public {
        mockToken1.mint(address(paymentSplitter), 10 ether);
        mockToken2.mint(address(paymentSplitter), 20 ether);

        vm.deal(address(paymentSplitter), 100);

        address payable[] memory newPayees = new address payable[](2);
        uint256[] memory newShares = new uint256[](2);
        newPayees[0] = payable(payee3);
        newPayees[1] = payable(payee4);
        newShares[0] = 1;
        newShares[1] = 3;
        vm.prank(defaultAdmin);
        paymentSplitter.overridePayees(newPayees, newShares);

        assertEq(paymentSplitter.releasable(payee3), 25);
        assertEq(paymentSplitter.releasable(payee4), 75);

        assertEq(paymentSplitter.releasable(mockToken1, payee3), 2.5 ether);
        assertEq(paymentSplitter.releasable(mockToken1, payee4), 7.5 ether);

        assertEq(paymentSplitter.releasable(mockToken2, payee3), 5 ether);
        assertEq(paymentSplitter.releasable(mockToken2, payee4), 15 ether);
    }

    function testAddErc20() public {
        MockERC20 token1 = new MockERC20("Token1", "T1");
        MockERC20 token2 = new MockERC20("Token2", "T2");
        IERC20[] memory newErc20s = new IERC20[](2);
        newErc20s[0] = token1;
        newErc20s[1] = token2;

        vm.startPrank(registrarAdmin);
        paymentSplitter.addToAllowlist(newErc20s);
        assertEq(paymentSplitter.erc20Allowlist().length, 4);
        assertEq(address(paymentSplitter.erc20Allowlist()[2]), address(token1));
        assertEq(address(paymentSplitter.erc20Allowlist()[3]), address(token2));

        paymentSplitter.addToAllowlist(newErc20s);
        assertEq(paymentSplitter.erc20Allowlist().length, 4);

        paymentSplitter.removeFromAllowlist(token1);
        assertEq(paymentSplitter.erc20Allowlist().length, 3);
        assertEq(address(paymentSplitter.erc20Allowlist()[2]), address(token2));
        vm.stopPrank();
    }

    function testReceiveNativeTokenEvent() public {
        vm.deal(address(this), 100);
        vm.expectEmit(true, true, false, false, address(paymentSplitter));
        emit PaymentReceived(address(this), 100);
        Address.sendValue(payable(address(paymentSplitter)), 100);
    }
}
