// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ERC20PresetFixedSupply} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import { ERC20Input, ERC721Input, ERC1155Input } from "../ICraftingRecipe.sol";
import {CraftingFactor} from "contracts/crafting/CraftingFactory.sol";


contract CraftingFactoryTest is Test {

    CraftingFactory public craftingFactory;


    address public bank;
    address public player;
    address public player2;

    function setUp() public virtual {
        bank = makeAddr("bank");
        player = makeAddr("player");
        player2 = makeAddr("player2");

        craftingFactory = new CraftingFactory();

        IERC20 erc20 = new ERC20PresetFixedSupply("TOKEN", "TOK", 1000, bank);
        bank.transfer(player, 100);
    }

    function testHappyPath() public {

        // TODO

    }
