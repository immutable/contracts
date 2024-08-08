// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Commands} from "./Commands.sol";
import {IERC721MintableBurnable} from "./IERC721MintableBurnable.sol";

contract Crafting {
    event Crafted(
        bytes32 _craftId,
        address _player,
        Commands.Command[] _commands,
        address _signer,
        uint256 _deadline
    );

    function execute(
        // bytes32 _craftId,
        // address _player,
        Commands.Command[] memory _commands
        // address _signer,
        // uint256 _deadline,
        // bytes calldata _signature
    ) external {
      for (uint256 i = 0; i < _commands.length; i++) {
        Commands.Command memory command = _commands[i];
        if (command.commandType == Commands.CommandType.ERC721Burn) {
          (address owner, uint256 tokenId) = abi.decode(command.data, (address, uint256));
          IERC721MintableBurnable(command.token).safeBurn(owner, tokenId);
        } else if (command.commandType == Commands.CommandType.ERC721Transfer) {
          (address from, address to, uint256 tokenId) = abi.decode(command.data, (address, address, uint256));
          IERC721MintableBurnable(command.token).safeTransferFrom(from, to, tokenId);
        } else if (command.commandType == Commands.CommandType.ERC721Mint) {
          (address to, uint256 tokenId) = abi.decode(command.data, (address, uint256));
          IERC721MintableBurnable(command.token).safeMint(to, tokenId);
        } 
      }
    }
}
