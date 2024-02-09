// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20Input, ERC721Input, ERC1155Input } from "../ICraftingRecipe.sol";
import { AbstractCraftingRecipe } from "../AbstractCraftingRecipe.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleRecipe is AbstractCraftingRecipe {
    IERC721 public token;

    constructor(address _craftingFactory, IERC721 _token) AbstractCraftingRecipe(_craftingFactory) {
        token = _token;
    }

    function beforeTransfers(
        uint256,
        ERC20Input[] calldata erc20s,
        ERC721Input[] calldata erc721s,
        ERC1155Input[] calldata erc1155s,
        bytes calldata
    ) external view onlyCraftingFactory {

        require(erc20s.length == 0, "No ERC20s allowed.");
        require(erc1155s.length == 0, "No ERC1155s allowed.");
        require(erc721s.length == 1, "Must be only one ERC721 input.");

        ERC721Input memory input = erc721s[0];
        require(input.erc721 == token, "Must be crafting game assets."); 
        require(input.destination == address(0), "Only allowed destination is 0x0.");
        
        // No need to check that the 5 assets are unique as transferring them will fail in the Factory. 

        // Can log any events you want
    }

    function afterTransfers(uint256 _craftID, address _player, bytes calldata _data) external onlyCraftingFactory {
        // TODO
        // (address nft, uint256 tokenId) = abi.decode(_data, (address, uint256));
        // IERC721(nft).mint(_player, tokenId);

        // Can log any events you want
    }

}