pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockWallet {
    function transferNFT(address token, address from, address to, uint256 tokenId) external {
        IERC721(token).transferFrom(from, to, tokenId);
    }
}
