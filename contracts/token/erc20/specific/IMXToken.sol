// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract IMXToken is ERC20Capped, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor(address minter) ERC20("Immutable X", "IMX") ERC20Capped(2000000000000000000000000000) {
    _setupRole(MINTER_ROLE, minter);
  }

  modifier checkRole(
    bytes32 role,
    address account,
    string memory message
  ) {
    require(hasRole(role, account), message);
    _;
  }

  function mint(address to, uint256 amount) external checkRole(MINTER_ROLE, msg.sender, "Caller is not a minter") {
    super._mint(to, amount);
  }
}