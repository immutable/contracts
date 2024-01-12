// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import { IRecipe, ERC20Input, ERC721Input, ERC1155Input } from "../IRecipe.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleRecipe is IRecipe {

    IERC721 public token;
    address private factory;

    constructor(IERC721 _token, address _factory) {
        token = _token;
        factory = _factory;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "Caller must be Factory");
        _;
    }

    function beforeTransfers(
        uint256,
        ERC20Input[] calldata erc20s,
        ERC721Input[] calldata erc721s,
        ERC1155Input[] calldata erc1155s,
        bytes calldata
    ) external view onlyFactory {

        require(erc20s.length == 0, "No ERC20s allowed.");
        require(erc1155s.length == 0, "No ERC1155s allowed.");
        require(erc721s.length == 1, "Must be only one ERC721 input.");

        ERC721Input memory input = erc721s[0];
        require(input.erc721 == token, "Must be crafting game assets."); 
        require(input.destination == address(0), "Only allowed destination is 0x0.");
        
        // No need to check that the 5 assets are unique as transferring them will fail in the Factory. 

        // Can log any events you want
    }

    function afterTransfers(uint256 craftID, bytes calldata data) external onlyFactory {
        // mint a new NFT to the user
        // token.mint() etc. 

        // Can log any events you want
    }

}