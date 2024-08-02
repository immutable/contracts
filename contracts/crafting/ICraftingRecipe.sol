// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct ERC1155Asset {
    uint256 tokenID;
    uint256 amount;
}

struct ERC1155Input {
    IERC1155 erc1155;
    ERC1155Asset[] assets;
    address destination;
}

struct ERC721Input {
    IERC721 erc721;
    uint256[] tokenIDs;
    address destination;
}

struct ERC20Input {
    IERC20 erc20;
    uint256 amount;
    address destination;
}

interface ICraftingRecipe {
    error OnlyCraftingFactory(address _caller);

    function beforeTransfers(
        uint256 craftID,
        address _player,
        ERC20Input[] calldata erc20s,
        ERC721Input[] calldata erc721s,
        ERC1155Input[] calldata erc1155s,
        bytes calldata data
    ) external;

    function afterTransfers(uint256 craftID, address _player, bytes calldata data) external;
}
