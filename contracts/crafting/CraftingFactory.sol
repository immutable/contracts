// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IRecipe, ERC1155Input, ERC721Input, ERC20Input, ERC1155Asset} from "./IRecipe.sol";

contract CraftingFactory {
    event CraftComplete(uint256 indexed craftID, IRecipe indexed recipe);

    uint256 public craftCounter;


    /**
     * @notice Transfer some tokens and then execute an arbitrary action.
     * @dev The set of allowed token actions can be controlled by the a crafting recipe.
     * @dev The crafting receipt also defines the arbitrary action.
     * @dev The msg.sender is assumed to be the game player's EOA or Passport wallet contract.
     * @param receipe Contract that defines the allowable set of inputs to crafting and the actions to do post transfers.
     * @param erc20Inputs Tokens to be transferred.
     * @param erc721Inputs Tokens to be transferred.
     * @param erc1155Inputs Tokens to be transferred.
     * @param data ABI encoded parameters to the crafting logic post transfer.
     */
    function craft(
        IRecipe recipe,
        ERC20Input[] calldata erc20Inputs,
        ERC721Input[] calldata erc721Inputs,
        ERC1155Input[] calldata erc1155Inputs,
        bytes calldata data
    ) external {
        uint craftID = craftCounter++;

        recipe.beforeTransfers(craftID, msg.sender, erc20Inputs, erc721Inputs, erc1155Inputs, data);

        for (uint256 i = 0; i < erc20Inputs.length; i++) {
            ERC20Input memory input = erc20Inputs[i];
            input.erc20.transferFrom(msg.sender, input.destination, input.amount);
        }

        for (uint256 i = 0; i < erc721Inputs.length; i++) {
            ERC721Input memory input = erc721Inputs[i];
            for (uint256 j = 0; j < input.tokenIDs.length; j++) {
                input.erc721.safeTransferFrom(msg.sender, input.destination, input.tokenIDs[j]);
            }
        }

        for (uint256 i = 0; i < erc1155Inputs.length; i++) {
            ERC1155Input memory input = erc1155Inputs[i];
            for (uint256 j = 0; j < input.assets.length; j++) {
                ERC1155Asset memory asset = input.assets[j];
                input.erc1155.safeTransferFrom(msg.sender, input.destination, asset.tokenID, asset.amount, "0x0");
            }
        }

        recipe.afterTransfers(craftID, msg.sender, data);

        emit CraftComplete(craftID, recipe);
    }
}
