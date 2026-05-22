// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockOnReceive {
    IERC721 public immutable TOKEN_ADDRESS;
    address private immutable RECIPIENT;

    // slither-disable-next-line missing-zero-check
    constructor(IERC721 _tokenAddress, address _recipient) {
        TOKEN_ADDRESS = _tokenAddress;
        RECIPIENT = _recipient;
    }

    // Attempt to transfer token to another address on receive
    function onERC721Received(
        address,
        /* operator */ address,
        /* from */ uint256 tokenId,
        bytes calldata /* data */
    ) public returns (bytes4) {
        TOKEN_ADDRESS.transferFrom(address(this), RECIPIENT, tokenId);
        return this.onERC721Received.selector;
    }
}
