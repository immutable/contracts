// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockOnReceive {
    IERC721 public immutable tokenAddress;
    address private immutable recipient;

    // slither-disable-next-line missing-zero-check
    constructor(IERC721 _tokenAddress, address _recipient) {
        tokenAddress = _tokenAddress;
        recipient = _recipient;
    }

    // Attempt to transfer token to another address on receive
    function onERC721Received(address, /* operator */ address, /* from */ uint256 tokenId, bytes calldata /* data */ )
        public
        returns (bytes4)
    {
        tokenAddress.transferFrom(address(this), recipient, tokenId);
        return this.onERC721Received.selector;
    }
}
