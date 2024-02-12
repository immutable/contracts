// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import {ICraftingRecipe} from "./ICraftingRecipe.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract AbstractCraftingRecipe is ICraftingRecipe {
    modifier onlyCraftingFactory() {
        if (msg.sender != craftingFactory) {
            revert OnlyCraftingFactory(msg.sender);
        }
        _;
    }

    address public craftingFactory;

    constructor(address _craftingFactory) {
        craftingFactory = _craftingFactory;
    }
}
