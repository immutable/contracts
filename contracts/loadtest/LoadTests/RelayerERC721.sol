// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RelayerERC721 is ERC721 {
    constructor() ERC721("RelayerERC721", "R721") {}

    /**
     * mint a single token. Assign the current token Id to the NFT, and return the
     * token Id to the caller.
     *
     * @param owner Owner of the ERC721 token.
     * @param tokenId unique identifier for token.
     */
    function mint(address owner, uint256 tokenId) public {
        require(owner != address(0), "ERC721: address zero is not a valid owner");

        _mint(owner, tokenId);
    }
}
