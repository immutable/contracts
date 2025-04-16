// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mint is ERC721 {
    uint256 public tokenId;

    constructor() ERC721("ERC721Mint", "721M") {}

    /**
     * mint a batch of ERC721 tokens to the `to` address.
     *
     * @param to Owner of the ERC721 token.
     * @param amount The number of tokens to mint to the owner. The tokenId is sequentially incremented and assigned.
     */
    function mint(address to, uint256 amount) public {
        for (uint i; i < amount; i++) {
            _mint(to, tokenId);
            tokenId++;
        }
    }
}
