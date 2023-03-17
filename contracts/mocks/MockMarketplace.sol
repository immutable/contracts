pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract MockMarketplace {
    IERC721 public tokenAddress;

    constructor(IERC721 _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function executeTransfer(address recipient, uint256 _tokenId) external {
        tokenAddress.transferFrom(msg.sender, recipient, _tokenId);
    }
}
