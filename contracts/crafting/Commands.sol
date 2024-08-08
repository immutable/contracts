// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Commands {
    enum CommandType {
        ERC721Mint,
        ERC721Burn,
        ERC721Transfer,
        ERC20Mint,
        ERC20Transfer,
        ERC1155Mint,
        ERC1155Burn,
        ERC1155Transfer
    }

    struct Command {
        address token;
        CommandType commandType;
        bytes data;
    }
}
