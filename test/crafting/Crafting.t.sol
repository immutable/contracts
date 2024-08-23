// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployOperatorAllowlist} from "../utils/DeployAllowlistProxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {ImmutableERC1155} from "../../contracts/token/erc1155/preset/ImmutableERC1155.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {GuardedMulticaller} from "../../contracts/multicall/GuardedMulticaller.sol";

import {SigUtils} from "./SigUtils.sol";

contract CraftingTest is Test {
  OperatorAllowlistUpgradeable public operatorAllowlist;
  ImmutableERC1155 public game1155;
  ImmutableERC721 public game721;
  GuardedMulticaller public multicaller;
  SigUtils public sigUtils;

  uint256 public imtblPrivateKey = 1;
  uint256 public gameStudioPrivateKey = 2;
  uint256 public playerOnePrivateKey = 3;
  uint256 public signingAuthorityPrivateKey = 4;

  address public imtbl = vm.addr(imtblPrivateKey);
  address public gameStudio = vm.addr(gameStudioPrivateKey);
  address public playerOne = vm.addr(playerOnePrivateKey);
  address public signingAuthority = vm.addr(signingAuthorityPrivateKey);

  address public proxyAddr;

  function setUp() public {
    DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
    proxyAddr = deployScript.run(imtbl, imtbl, imtbl);
    operatorAllowlist = OperatorAllowlistUpgradeable(proxyAddr);

    assertTrue(operatorAllowlist.hasRole(operatorAllowlist.REGISTRAR_ROLE(), imtbl));

    game1155 = new ImmutableERC1155(
        gameStudio, "test1155", "test-base-uri", "test-contract-uri", address(operatorAllowlist), gameStudio, 0
    );

    vm.prank(gameStudio);
    game1155.grantMinterRole(gameStudio);
    assertTrue(game1155.hasRole(game1155.MINTER_ROLE(), gameStudio));

    game721 = new ImmutableERC721(
        gameStudio, "test721", "TST", "test-base-uri", "test-contract-uri", address(operatorAllowlist), gameStudio, 0
    );

    vm.prank(gameStudio);
    game721.grantMinterRole(gameStudio);
    assertTrue(game721.hasRole(game721.MINTER_ROLE(), gameStudio));

    // Deploy game studio's multicaller contract
    multicaller = new GuardedMulticaller(gameStudio, "multicaller", "1");
    assertTrue(multicaller.hasRole(multicaller.DEFAULT_ADMIN_ROLE(), gameStudio));

    // Grant signer role to signing authority
    vm.prank(gameStudio);
    multicaller.grantMulticallSignerRole(signingAuthority);
    assertTrue(multicaller.hasRole(multicaller.MULTICALL_SIGNER_ROLE(), signingAuthority));

    // permit required functions
    GuardedMulticaller.FunctionPermit[] memory functionPermits = new GuardedMulticaller.FunctionPermit[](1);
    GuardedMulticaller.FunctionPermit memory mintPermit = GuardedMulticaller.FunctionPermit(
      address(game721),
      game721.safeMint.selector,
      true
    );
    functionPermits[0] = mintPermit;
    vm.prank(gameStudio);
    multicaller.setFunctionPermits(functionPermits);
    assertTrue(multicaller.isFunctionPermitted(address(game721), game721.safeMint.selector));

    sigUtils = new SigUtils("multicaller", "1");
  }

  function testMintViaMulticaller() public {
    // game721.safeMint(playerOne, 1);

    bytes32 referenceID = keccak256("testMintViaMulticaller:1");

    address[] memory targets = new address[](1);
    targets[0] = address(game721);

    bytes[] memory data = new bytes[](1);
    data[0] = abi.encodeWithSignature("safeMint(address,uint256)", playerOne, 1);

    uint256 deadline = block.timestamp + 10;

    // Construct signature
    bytes32 structHash = sigUtils.getTypedDataHash(referenceID, targets, data, deadline);

    vm.startPrank(signingAuthority);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signingAuthorityPrivateKey, structHash);
    bytes memory signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
    vm.stopPrank();

    vm.prank(playerOne);
    multicaller.execute(signingAuthority, referenceID, targets, data, deadline, signature);

    assertTrue(game721.balanceOf(playerOne) == 1);

  }

  // function testSimpleCraft() public {
  //   // Game studio mints 10 of tokenID 1 on 1155 to user A
  //   vm.prank(gameStudio);
  //   game1155.safeMint(playerOne, 1, 10, "");
  //   assertTrue(game1155.balanceOf(playerOne, 1) == 10);

  //   // Game studio mints 10 of tokenID 2 on 1155 to user A
  //   vm.prank(gameStudio);
  //   game1155.safeMint(playerOne, 2, 10, "");
  //   assertTrue(game1155.balanceOf(playerOne, 2) == 10);

  //   // Perform a craft using the Multicaller
  //   // - burn 1 of 1155 tokenID 1
  //   // - burn 2 of 1155 tokenID 2
  //   // - mint 1 721 to playerOne
  //   address[] memory targets = new address[](3);
  //   targets[0] = address(game1155);
  //   targets[1] = address(game1155);
  //   targets[2] = address(game721);

  //   bytes[] memory data = new bytes[](3);
  //   data[0] = "";
  //   data[1] = "";
  //   data[2] = "";

  //   uint256 deadline = block.timestamp + 10;

  //   vm.prank(playerOne);
  //   multicaller.execute(signingAuthority, referenceID, targets, data, deadline, "");

  //   // assertTrue(game1155.balanceOf(playerOne, 1) == 9);
  //   // assertTrue(game1155.balanceOf(playerOne, 2) == 8);
  //   // assertTrue(game721.balanceOf(owner) == 1);
  // }
}