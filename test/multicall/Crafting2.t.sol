// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {DeployOperatorAllowlist} from "../utils/DeployAllowlistProxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {ImmutableERC1155} from "../../contracts/token/erc1155/preset/ImmutableERC1155.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {GuardedMulticaller2} from "../../contracts/multicall/GuardedMulticaller2.sol";

import {SigUtils} from "./SigUtils.t.sol";

contract Crafting2Test is Test {
  OperatorAllowlistUpgradeable public operatorAllowlist;
  ImmutableERC1155 public game1155;
  ImmutableERC721 public game721;
  GuardedMulticaller2 public multicaller;
  SigUtils public sigUtils;

  uint256 public imtblPrivateKey = 1;
  uint256 public gameStudioPrivateKey = 2;
  uint256 public signingAuthorityPrivateKey = 3;
  uint256 public playerPrivateKey = 4;

  address public imtbl = vm.addr(imtblPrivateKey);
  address public gameStudio = vm.addr(gameStudioPrivateKey);
  address public signingAuthority = vm.addr(signingAuthorityPrivateKey);
  address public player = vm.addr(playerPrivateKey);

  address public proxyAddr;

  string public multicallerName = "multicaller-name";
  string public multicallerVersion = "multicaller-version";

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

    // Deploy game studio's multicaller contract
    multicaller = new GuardedMulticaller2(gameStudio, multicallerName, multicallerVersion);
    assertTrue(multicaller.hasRole(multicaller.DEFAULT_ADMIN_ROLE(), gameStudio));

    // Add multicaller to operator allowlist
    address[] memory allowlistTargets = new address[](1);
    allowlistTargets[0] = address(multicaller);

    vm.prank(imtbl);
    operatorAllowlist.addAddressesToAllowlist(allowlistTargets);
    assertTrue(operatorAllowlist.isAllowlisted(address(multicaller)));

    // Grant minter role to the game studio
    vm.startPrank(gameStudio);
    game721.grantMinterRole(gameStudio);
    assertTrue(game721.hasRole(game721.MINTER_ROLE(), gameStudio));

    // Grant minter role to the multicaller contract
    game721.grantMinterRole(address(multicaller));
    assertTrue(game721.hasRole(game721.MINTER_ROLE(), address(multicaller)));
    vm.stopPrank();

    // Grant signer role to signing authority
    vm.prank(gameStudio);
    multicaller.grantMulticallSignerRole(signingAuthority);
    assertTrue(multicaller.hasRole(multicaller.MULTICALL_SIGNER_ROLE(), signingAuthority));

    sigUtils = new SigUtils(multicallerName, multicallerVersion, address(multicaller));
  }

  function testCraft() public {
    // Game studio mints 10 of tokenID 1 on 1155 to player
    vm.prank(gameStudio);
    game1155.safeMint(player, 1, 10, "");
    assertTrue(game1155.balanceOf(player, 1) == 10);

    // Game studio mints 10 of tokenID 2 on 1155 to player
    vm.prank(gameStudio);
    game1155.safeMint(player, 2, 10, "");
    assertTrue(game1155.balanceOf(player, 2) == 10);

    // Perform a craft using the Multicaller
    // - burn 1 of 1155 tokenID 1
    // - burn 2 of 1155 tokenID 2
    // - mint 1 721 to player

    bytes32 referenceID = keccak256("testCraft:1");

    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;

    uint256[] memory values = new uint256[](2);
    values[0] = 1;
    values[1] = 2;

    // Construct signature
    GuardedMulticaller2.Call[] memory calls = new GuardedMulticaller2.Call[](2);

    calls[0] = GuardedMulticaller2.Call(
      address(game1155),
      "burnBatch(address,uint256[],uint256[])",
      abi.encode(player, ids, values)
    );

    calls[1] = GuardedMulticaller2.Call(
      address(game721),
      "safeMint(address,uint256)",
      abi.encode(player, uint256(1))
    );

    uint256 deadline = block.timestamp + 10;

    bytes32 structHash = sigUtils.hashTypedData(referenceID, calls, deadline);

    vm.startPrank(signingAuthority);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signingAuthorityPrivateKey, structHash);
    bytes memory signature = abi.encodePacked(r, s, v);
    vm.stopPrank();

    // Give multicaller approve to burn
    vm.startPrank(player);
    game1155.setApprovalForAll(address(multicaller), true);
    assertTrue(game1155.isApprovedForAll(player, address(multicaller)));

    multicaller.execute(signingAuthority, referenceID, calls, deadline, signature);
    vm.stopPrank();

    assertTrue(game1155.balanceOf(player, 1) == 9);
    assertTrue(game1155.balanceOf(player, 2) == 8);
    assertTrue(game721.balanceOf(player) == 1);
  }

  // function testSignature() public {
  //   bytes32 referenceID = keccak256("testCraft:1");

  //   address[] memory targets = new address[](2);
  //   targets[0] = address(game1155);
  //   targets[1] = address(game721);

  //   bytes[] memory data = new bytes[](2);

  //   uint256[] memory ids = new uint256[](2);
  //   ids[0] = 1;
  //   ids[1] = 2;

  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 1;
  //   values[1] = 2;

  //   data[0] = abi.encodeWithSignature("burnBatch(address,uint256[],uint256[])", player, ids, values);
  //   data[1] = abi.encodeWithSignature("safeMint(address,uint256)", player, 1);

  //   uint256 deadline = block.timestamp + 10;

  //   // Construct signature
  //   bytes32 structHash = sigUtils.hashTypedData(referenceID, calls, deadline);

  //   console.log("structHash", structHash);
  // }
}