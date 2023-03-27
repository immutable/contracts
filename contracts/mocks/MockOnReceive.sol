pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockOnReceive {
    IERC721 public tokenAddress;
    address private recipient;

    constructor(IERC721 _tokenAddress, address _recipient) {
        tokenAddress = _tokenAddress;
        recipient = _recipient;
    }

    // Attempt to transfer token to another address on receive
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public returns (bytes4) {
        tokenAddress.transferFrom(address(this), recipient, tokenId);
        return this.onERC721Received.selector;
    }
}
