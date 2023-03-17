pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "hardhat/console.sol";

contract MockMarketplace {
    IERC721 public tokenAddress;
    IERC2981 public royaltyAddress;

    constructor(address _tokenAddress) {
        tokenAddress = IERC721(_tokenAddress);
        royaltyAddress = IERC2981(_tokenAddress);
    }

    function executeTransfer(address recipient, uint256 _tokenId) public payable {
        tokenAddress.transferFrom(msg.sender, recipient, _tokenId);
    }

    function executeTransferRoyalties(address from, address recipient, uint256 _tokenId, uint256 price) public payable {
        require(msg.value == price, "insufficient msg.value");
        (address receiver, uint256 royaltyAmount) = royaltyAddress.royaltyInfo(_tokenId, price);
        console.log("%s, %s",receiver, royaltyAmount);
        // tokenAddress.transferFrom(from, recipient, _tokenId);
    }
}
