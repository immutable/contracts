// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mint is ERC721 {
    uint256 public tokenId;
    constructor() ERC721("ERC721Mint", "721M") {
    }

    function mint(address to, uint256 amount) public {
        for (uint i; i < amount; i++) {
            _mint(to, tokenId);
            tokenId++;
        }
        
    }
}