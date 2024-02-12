// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ERC20Input, ERC721Input, ERC1155Input } from "../ICraftingRecipe.sol";
import { AbstractCraftingRecipe } from "contracts/crafting/AbstractCraftingRecipe.sol";

contract MockRecipeERC1155 is AbstractCraftingRecipe {
    error NoERC20sAccepted();
    error NoERC721sAccepted();
    error IncorrectNumberOfERC1155s();
    error WrongDeviceToken(address _token);
    error WrongInputToken(address _token);
    error WrongOutputToken(address _token);
    error IncorrectDeviceDestination(address _destination);
    error IncorrectInputDestination(address _destination);
    error IncorrectOutputDestination(address _destination);
    error OnlyUseOneCraftingDeviceAtATime(uint256 _len);
    error ZeroCraftingDevices(uint256 _craftingDevice);


    error NoInputAssetsProvided();
    error OnlyOneOutputAssetAllowed();

    error GoldenSwordCraftingWrongNumberAssets();
    error GoldSwordCraftingWrongAssets();

    uint256 private constant GOLDEN_SWORD = 2;
    uint256 private constant DIAMOND_SWORD = 2;
    uint256 private constant DIAMONDS = 5;
    uint256 private constant ANVIL = 100;


    address public gameTokens;
    address public gameContract;

    constructor(address _craftingFactory, address _gameTokens, address _gameContract) AbstractCraftingReceipt(_craftingFactory) {
        gameTokens = _gameTokens;
        gameContract = _gameContract;
    }


    /**
     * @notice Expect two ERC 1155 objects: 
     *          First: crafting device.
     *          Second: inputs to crafting.
     *          Third: output of crafting
     */
    function beforeTransfers(
        uint256 /* craftID */,
        address _player, 
        ERC20Input[] calldata erc20s,
        ERC721Input[] calldata erc721s,
        ERC1155Input[] calldata erc1155s,
        bytes calldata /* data */
    ) external view onlyFactory {
        if (erc20s.length != 0) {
            revert NoERC20sAccepted();
        }
        if (erc721s.length != 0) {
            revert NoERC721sAccepted();
        }
        if (erc1155s.length != 3) {
            revert IncorrectNumberOfERC1155s();
        }

        ERC1155 memory erc1155Device = erc1155s[0];
        ERC1155 memory erc1155Input = erc1155s[1];
        ERC1155 memory erc1155Output = erc1155s[2];

        // Check crafting device.
        IERC1155 tokenContract = erc1155Device.erc1155;
        if (address(tokenContract) != gameToken) {
            revert WrongDeviceToken(address(tokenContract));
        }
        // Crafting device should stay with the player.
        if (erc1155Device.destination != _player) {
            revert IncorrectDevicceDestination(erc1155Output.destination);
        }
        if (erc1155Device.assets.length != 1) {
            revert OnlyUseOneCraftingDeviceAtATime(erc1155Device.assets.length);
        }
        uint256 craftingDevice = erc1155Device.assets[0].tokenId;
        if (erc1155Device.assets[0].amount == 0) {
            revert ZeroCraftingDevices(craftingDevice);
        }

        // Check inputs.
        IERC1155 tokenContract = erc1155Input.erc1155;
        if (address(tokenContract) != gameToken) {
            revert WrongInputToken(address(tokenContract));
        }
        if (erc1155Input.destination != gameContract) {
            revert IncorrectInputDestination(erc1155Input.destination);
        }
        ERC1155Asset[] memory inputAssets = erc1155Input.assets;
        if (inputAssets.length == 0) {
            revert NoInputAssetsProvided();
        }

       // Check output.
         tokenContract = erc1155Output.erc1155;
        if (address(tokenContract) != gameToken) {
            revert WrongOutputToken(address(tokenContract));
        }
        if (erc1155Output.destination != _player) {
            revert IncorrectOutputDestination(erc1155Output.destination);
        }
        ERC1155Asset[] memory outputAssets = erc1155Output.assets;
        if (outputAssets.length != 1) {
            revert OnlyOneOutputAssetAllowed(outputAssets.length);
        }
        ERC1155Asset memory outputAsset = outputAssets[0];


        // Check for valid combinations of input assets and resulting output asset.
        if ((craftingDevice == ANVIL) && (inputAssets[0].tokenID == GOLDEN_SWORD)) {
            if (inputAssets.length == 2) {
                revert GoldenSwordCraftingWrongNumberAssets(assets.length);
            }
            if ((inputAssets[0].amount != 1) ||
                (inputAssets[1].tokenID != DIAMONDS) ||
                (inputAssets[1].amount != 5) ||
                (outputAsset.tokenID != DIAMOND_SWORD) ||
                (outputAsset.amount != 1) ) {
                revert GoldSwordCraftingWrongAssets();
            }
        }
        else {
            revert UnknownCraftingCombination();
        }
    }

    function afterTransfers(
        uint256 /* _craftID */, 
        address /* _player */, 
        bytes calldata /* _data */ ) external onlyFactory {
        // Nothing to do.
    }
}