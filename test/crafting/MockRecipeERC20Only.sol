// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ERC20Input, ERC721Input, ERC1155Input } from "../ICraftingRecipe.sol";
import { AbstractCraftingRecipe } from "../AbstractCraftingRecipe.sol";

contract MockRecipeERC20Only is ICraftingRecipe {
    error InvalidTokens();
    error WrongERC20(address _token);
    error NotEnough(uint256);

    address public gameToken;

    constructor(address _craftingFactory, address _gameToken) AbstractCraftingReceipt(_craftingFactory) {
        gameToken = _gameToken;
    }


    function beforeTransfers(
        uint256,
        ERC20Input[] calldata erc20s,
        ERC721Input[] calldata erc721s,
        ERC1155Input[] calldata erc1155s,
        bytes calldata
    ) external view onlyFactory {
        // TODO split this out
        if (erc20s.length != 1 || erc721s.length != 0 || erc1155s.length != 0) {
            revert InvalidTokens();
        }
        if (address(erc20s[0].erc20) != gameToken) {
            revert WrongERC20(address(erc20s[0].erc20));
        }
        if (erc20s[0].amount < 10) {
            revert NotEnough(erc20s[0].amount);
        }
        // TODO check destination - is it looping back to same user?

    }

    function afterTransfers(uint256 _craftID, address _player, bytes calldata _data) external onlyFactory {
        // TODO do something
    }

}